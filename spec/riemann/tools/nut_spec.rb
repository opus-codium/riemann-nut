# frozen_string_literal: true

require "riemann/tools/nut"

RSpec.describe Riemann::Tools::Nut do
  let(:instance) { described_class.new }
  let(:ups) { "ups@localhost" }

  before do
    allow(Open3).to receive(:capture2).with("upsc", "ups@localhost").and_return([File.read("spec/fixtures/upsc.no-battery.output"), double])
    instance.invalidate_cache
  end

  describe "#report_battery_charge" do
    before do
      allow(instance).to receive(:report).with(
        service: "ups@localhost battery charge",
        metric: 100,
        description: "100 %",
        state: "ok"
      )
    end

    it "reports battery charge" do
      instance.report_battery_charge(ups)
      expect(instance).to have_received(:report)
    end
  end

  describe "#report_battery_voltage" do
    before do
      allow(instance).to receive(:report).with(
        service: "ups@localhost battery voltage",
        metric: 13.4,
        description: "13.4 V",
        state: "ok"
      )
    end

    it "reports battery voltage" do
      instance.report_battery_voltage(ups)
      expect(instance).to have_received(:report)
    end
  end

  describe "#report_input_voltage" do
    before do
      allow(instance).to receive(:report).with(
        service: "ups@localhost input voltage",
        metric: 230.0,
        description: "230.0 V",
        state: "ok"
      )
    end

    it "reports input voltage" do
      instance.report_input_voltage(ups)
      expect(instance).to have_received(:report)
    end
  end

  describe "#report_ups_alarm" do
    before do
      allow(instance).to receive(:report).with(
        service: "ups@localhost ups alarm",
        description: "Replace battery! No battery installed!",
        state: "critical"
      )
    end

    it "reports ups alarm" do
      instance.report_ups_alarm(ups)
      expect(instance).to have_received(:report)
    end
  end

  describe "#report_ups_load" do
    before do
      ARGV.replace(["--load-warning", load_warning, "--load-critical", load_critical])

      allow(instance).to receive(:report).with(
        service: "ups@localhost ups load",
        metric: 12.0,
        description: "12.0 W",
        state: expected_state
      )
    end

    context "without limits" do
      let(:load_warning) { 0 }
      let(:load_critical) { 0 }
      let(:expected_state) { "ok" }

      it "reports ups load" do
        instance.report_ups_load(ups)
        expect(instance).to have_received(:report)
      end
    end

    context "when bellow limits" do
      let(:load_warning) { 15 }
      let(:load_critical) { 20 }
      let(:expected_state) { "ok" }

      it "reports ups load" do
        instance.report_ups_load(ups)
        expect(instance).to have_received(:report)
      end
    end

    context "when above warning watermark" do
      let(:load_warning) { 10 }
      let(:load_critical) { 25 }
      let(:expected_state) { "warning" }

      it "reports ups load" do
        instance.report_ups_load(ups)
        expect(instance).to have_received(:report)
      end
    end

    context "when above critical watermark" do
      let(:load_warning) { 5 }
      let(:load_critical) { 10 }
      let(:expected_state) { "critical" }

      it "reports ups load" do
        instance.report_ups_load(ups)
        expect(instance).to have_received(:report)
      end
    end
  end

  describe "#report_ups_status" do
    before do
      allow(instance).to receive(:report).with(
        service: "ups@localhost ups status",
        description: "ALARM OL RB",
        state: "critical"
      )
    end

    it "reports ups status" do
      instance.report_ups_status(ups)
      expect(instance).to have_received(:report)
    end
  end
end
