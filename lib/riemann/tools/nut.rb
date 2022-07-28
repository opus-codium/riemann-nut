# frozen_string_literal: true

require 'riemann/tools'

require 'open3'

module Riemann
  module Tools
    class Nut
      include Riemann::Tools

      opt :ups, 'UPS to connect to', type: :strings, default: ['ups@localhost']
      opt :load_warning, 'Load warning threshold', default: 0.0
      opt :load_critical, 'Load critical threshold', default: 0.0

      def tick
        invalidate_cache

        report_battery_charge
        report_battery_voltage
        report_input_voltage
        report_ups_alarm
        report_ups_load
        report_ups_status
      end

      def invalidate_cache
        @cached_data = {}
      end

      def upsc
        return @cached_data[:upsc] if @cached_data[:upsc]

        @cached_data[:upsc] = {}

        opts[:ups].each do |ups|
          output, _status = Open3.capture2('upsc', ups)

          data = {}
          output.lines.each do |line|
            next unless line.chomp =~ /\A([^:]+): (.*)\z/

            key = Regexp.last_match[1]
            value = Regexp.last_match[2].strip

            data[key] = value
          end

          @cached_data[:upsc][ups] = data
        rescue Errno::ENOENT
          @cached_data[:upsc][ups] = {}
        end

        @cached_data[:upsc]
      end

      def report_battery_charge
        opts[:ups].each do |ups|
          service = "#{ups} battery charge"
          battery_charge = Integer(upsc[ups]['battery.charge'])
          battery_state = if battery_charge < upsc[ups]['battery.charge.low'].to_i
                            'critical'
                          elsif battery_charge < upsc[ups]['battery.charge.warning'].to_i
                            'warning'
                          else
                            'ok'
                          end

          report(
            service: service,
            metric: battery_charge,
            state: battery_state,
            description: "#{battery_charge} %",
          )
        rescue TypeError
          report(
            service: service,
            state: 'critical',
          )
        end
      end

      def report_battery_voltage
        opts[:ups].each do |ups|
          service = "#{ups} battery voltage"
          battery_voltage = Float(upsc[ups]['battery.voltage'])

          report(
            service: service,
            metric: battery_voltage,
            state: 'ok',
            description: "#{battery_voltage} V",
          )
        rescue TypeError
          report(
            service: service,
            state: 'critical',
          )
        end
      end

      def report_input_voltage
        opts[:ups].each do |ups|
          service = "#{ups} input voltage"
          input_voltage = Float(upsc[ups]['input.voltage'])

          report(
            service: service,
            metric: input_voltage,
            state: 'ok',
            description: "#{input_voltage} V",
          )
        rescue TypeError
          report(
            service: service,
            state: 'critical',
          )
        end
      end

      def report_ups_alarm
        opts[:ups].each do |ups|
          next unless upsc[ups]['ups.alarm']

          report(
            service: "#{ups} ups alarm",
            state: 'critical',
            description: upsc[ups]['ups.alarm'],
          )
        end
      end

      def report_ups_load
        opts[:ups].each do |ups|
          service = "#{ups} ups load"
          ups_load = Float(upsc[ups]['ups.load'])
          ups_state = if opts[:load_critical].positive? && ups_load > opts[:load_critical]
                        'critical'
                      elsif opts[:load_warning].positive? && ups_load > opts[:load_warning]
                        'warning'
                      else
                        'ok'
                      end

          report(
            service: service,
            metric: ups_load,
            state: ups_state,
            description: "#{ups_load} W",
          )
        rescue TypeError
          report(
            service: service,
            state: 'critical',
          )
        end
      end

      def report_ups_status
        opts[:ups].each do |ups|
          # https://github.com/influxdata/telegraf/issues/6316#issuecomment-787008263
          ups_state = 'ok' if upsc[ups]['ups.status'] =~ /\b(OL)\b/
          ups_state = 'warning' if upsc[ups]['ups.status'] =~ /\b(OB|DISCHRG|BYPASS)\b/
          ups_state = 'critical' if upsc[ups]['ups.status'] =~ /\b(ALARM|OVER)\b/

          ups_state ||= 'critical'

          report(
            service: "#{ups} ups status",
            state: ups_state,
            description: upsc[ups]['ups.status'],
          )
        end
      end
    end
  end
end
