require "rails_helper"

describe FormService do
  subject(:form_service) do
    described_class.new(form)
  end

  let(:id) { 1 }
  let(:form) { create(:form, id:) }

  describe "#path_for_state" do
    context "when form is live" do
      let(:form) { create(:form, :live, id:) }

      it "returns live form path" do
        expect(form_service.path_for_state).to eq "/forms/#{id}/live"
      end
    end

    context "when form is archived" do
      let(:form) { create(:form, :archived, id:) }

      it "returns archived form path" do
        expect(form_service.path_for_state).to eq "/forms/#{id}/archived"
      end
    end

    context "when form is draft" do
      it "returns draft form path" do
        expect(form_service.path_for_state).to eq "/forms/#{id}"
      end
    end
  end
end
