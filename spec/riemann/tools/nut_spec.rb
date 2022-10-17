# frozen_string_literal: true

require 'riemann/tools/nut'

RSpec.describe Riemann::Tools::Nut do
  before do
    allow(Open3).to receive(:capture2).with('upsc', 'ups@localhost').and_return([File.read('spec/fixtures/upsc.no-battery.output'), double])
    subject.invalidate_cache
  end

  describe '#report_battery_charge' do
    it 'reports battery charge' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost battery charge',
        metric: 100,
        description: '100 %',
        state: 'ok',
      )
      subject.report_battery_charge
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_battery_voltage' do
    it 'reports battery voltage' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost battery voltage',
        metric: 13.4,
        description: '13.4 V',
        state: 'ok',
      )
      subject.report_battery_voltage
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_input_voltage' do
    it 'reports input voltage' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost input voltage',
        metric: 230.0,
        description: '230.0 V',
        state: 'ok',
      )
      subject.report_input_voltage
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_ups_alarm' do
    it 'reports ups alarm' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost ups alarm',
        description: 'Replace battery! No battery installed!',
        state: 'critical',
      )
      subject.report_ups_alarm
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_ups_load' do
    it 'reports ups load' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost ups load',
        metric: 12.0,
        description: '12.0 W',
        state: 'ok',
      )
      subject.report_ups_load
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_ups_status' do
    it 'reports ups status' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost ups status',
        description: 'ALARM OL RB',
        state: 'critical',
      )
      subject.report_ups_status
      expect(subject).to have_received(:report)
    end
  end
end
