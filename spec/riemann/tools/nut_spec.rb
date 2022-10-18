# frozen_string_literal: true

require 'riemann/tools/nut'

RSpec.describe Riemann::Tools::Nut do
  before do
    allow(Open3).to receive(:capture2).with('upsc', 'ups@localhost').and_return([File.read('spec/fixtures/upsc.no-battery.output'), double])
    subject.invalidate_cache
  end

  let(:ups) { 'ups@localhost' }

  describe '#report_battery_charge' do
    it 'reports battery charge' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost battery charge',
        metric: 100,
        description: '100 %',
        state: 'ok',
      )
      subject.report_battery_charge(ups)
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
      subject.report_battery_voltage(ups)
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
      subject.report_input_voltage(ups)
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
      subject.report_ups_alarm(ups)
      expect(subject).to have_received(:report)
    end
  end

  describe '#report_ups_load' do
    before do
      ARGV.replace(['--load-warning', load_warning, '--load-critical', load_critical])

      allow(subject).to receive(:report).with(
        service: 'ups@localhost ups load',
        metric: 12.0,
        description: '12.0 W',
        state: expected_state,
      )
    end

    context 'without limits' do
      let(:load_warning) { 0 }
      let(:load_critical) { 0 }
      let(:expected_state) { 'ok' }

      it 'reports ups load' do
        subject.report_ups_load(ups)
        expect(subject).to have_received(:report)
      end
    end

    context 'when bellow limits' do
      let(:load_warning) { 15 }
      let(:load_critical) { 20 }
      let(:expected_state) { 'ok' }

      it 'reports ups load' do
        subject.report_ups_load(ups)
        expect(subject).to have_received(:report)
      end
    end

    context 'when above warning watermark' do
      let(:load_warning) { 10 }
      let(:load_critical) { 25 }
      let(:expected_state) { 'warning' }

      it 'reports ups load' do
        subject.report_ups_load(ups)
        expect(subject).to have_received(:report)
      end
    end

    context 'when above critical watermark' do
      let(:load_warning) { 5 }
      let(:load_critical) { 10 }
      let(:expected_state) { 'critical' }

      it 'reports ups load' do
        subject.report_ups_load(ups)
        expect(subject).to have_received(:report)
      end
    end
  end

  describe '#report_ups_status' do
    it 'reports ups status' do
      allow(subject).to receive(:report).with(
        service: 'ups@localhost ups status',
        description: 'ALARM OL RB',
        state: 'critical',
      )
      subject.report_ups_status(ups)
      expect(subject).to have_received(:report)
    end
  end
end
