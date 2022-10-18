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

        opts[:ups].each do |ups|
          report_battery_charge(ups)
          report_battery_voltage(ups)
          report_input_voltage(ups)
          report_ups_alarm(ups)
          report_ups_load(ups)
          report_ups_status(ups)
        end
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

      def report_battery_charge(ups)
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

      def report_battery_voltage(ups)
        return unless upsc[ups]['battery.voltage']

        service = "#{ups} battery voltage"
        battery_voltage = Float(upsc[ups]['battery.voltage'])

        report(
          service: service,
          metric: battery_voltage,
          state: 'ok',
          description: "#{battery_voltage} V",
        )
      rescue TypeError => e
        report(
          service: service,
          state: 'critical',
          description: e.message,
        )
      end

      def report_input_voltage(ups)
        return unless upsc[ups]['input.voltage']

        service = "#{ups} input voltage"
        input_voltage = Float(upsc[ups]['input.voltage'])

        report(
          service: service,
          metric: input_voltage,
          state: 'ok',
          description: "#{input_voltage} V",
        )
      rescue TypeError => e
        report(
          service: service,
          state: 'critical',
          description: e.message,
        )
      end

      def report_ups_alarm(ups)
        return unless upsc[ups]['ups.alarm']

        report(
          service: "#{ups} ups alarm",
          state: 'critical',
          description: upsc[ups]['ups.alarm'],
        )
      end

      def report_ups_load(ups)
        service = "#{ups} ups load"
        ups_load = Float(upsc[ups]['ups.load'])

        report(
          service: service,
          metric: ups_load,
          state: ups_load_state(ups_load),
          description: "#{ups_load} W",
        )
      rescue TypeError => e
        report(
          service: service,
          state: 'critical',
          description: e.message,
        )
      end

      def ups_load_state(ups_load)
        if opts[:load_critical].positive? && ups_load > opts[:load_critical]
          'critical'
        elsif opts[:load_warning].positive? && ups_load > opts[:load_warning]
          'warning'
        else
          'ok'
        end
      end

      def report_ups_status(ups)
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
