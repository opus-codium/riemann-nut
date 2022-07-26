# frozen_string_literal: true

require 'riemann/tools/nut'

RSpec.describe Riemann::Tools::Nut do
  before do
    expect(Open3).to receive(:capture2).with('upsc', 'ups@localhost').and_return([File.read('spec/fixtures/upsc.no-battery.output'), double])
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
end
