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
          @cached_data[:upsc][ups] = upsc_ups(ups)
        rescue Errno::ENOENT
          @cached_data[:upsc][ups] = {}
        end

        @cached_data[:upsc]
      end

      def upsc_ups(ups)
        output, _status = Open3.capture2('upsc', ups)

        data = {}
        output.lines.each do |line|
          next unless line.chomp =~ /\A([^:]+): (.*)\z/

          key = Regexp.last_match[1]
          value = normalize(Regexp.last_match[2].strip)

          data[key] = value
        end

        data
      end

      def normalize(value)
        Integer(value)
      rescue ArgumentError
        begin
          Float(value)
        rescue ArgumentError
          value
        end
      end

      def report_battery_charge(ups)
        service = "#{ups} battery charge"

        report(
          service: service,
          metric: upsc[ups]['battery.charge'],
          state: battery_charge_state(ups),
          description: "#{upsc[ups]['battery.charge']} %",
        )
      rescue TypeError
        report(
          service: service,
          state: 'critical',
        )
      end

      def battery_charge_state(ups)
        if upsc[ups]['battery.charge'] < upsc[ups]['battery.charge.low']
          'critical'
        elsif upsc[ups]['battery.charge'] < upsc[ups]['battery.charge.warning']
          'warning'
        else
          'ok'
        end
      end

      def report_battery_voltage(ups)
        return unless upsc[ups]['battery.voltage']

        service = "#{ups} battery voltage"

        report(
          service: service,
          metric: upsc[ups]['battery.voltage'],
          state: 'ok',
          description: "#{upsc[ups]['battery.voltage']} V",
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

        report(
          service: service,
          metric: upsc[ups]['input.voltage'],
          state: 'ok',
          description: "#{upsc[ups]['input.voltage']} V",
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
