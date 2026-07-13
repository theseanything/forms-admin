require "rails_helper"

RSpec.describe Organisations::FilterInput, type: :model do
  describe "#has_filters?" do
    context "when the name filter is set" do
      subject(:input) { described_class.new(name: "foo") }

      it "returns true" do
        expect(input.has_filters?).to be true
      end
    end

    context "when the mou_signed filter is set" do
      subject(:input) { described_class.new(mou_signed: "true") }

      it "returns true" do
        expect(input.has_filters?).to be true
      end
    end

    context "when no filters are set" do
      subject(:input) { described_class.new }

      it "returns false" do
        expect(input.has_filters?).to be false
      end
    end
  end

  describe "#sort_options" do
    it "returns the correct options" do
      expect(described_class.new.sort_options).to eq([
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.name"), value: "name"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.users"), value: "users"),
        OpenStruct.new(label: I18n.t("organisations.index.filter.sort.forms"), value: "forms"),
      ])
    end
  end

  describe "#mou_signed_options" do
    it "returns the correct options" do
      expect(described_class.new.mou_signed_options).to eq([
        OpenStruct.new(label: I18n.t("organisations.index.filter.mou_signed.any")),
        OpenStruct.new(label: I18n.t("organisations.boolean.true"), value: "true"),
        OpenStruct.new(label: I18n.t("organisations.boolean.false"), value: "false"),
      ])
    end
  end
end
