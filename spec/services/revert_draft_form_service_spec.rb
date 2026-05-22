require "rails_helper"

describe RevertDraftFormService do
  subject(:revert_draft_form_service) { described_class.new(form) }

  describe "when using a live form with drafts" do
    let(:form) { create(:form, :live_with_draft) }
    let!(:live_content) { form.live_form_document.content.deep_dup }

    before do
      form.name = "Changed draft name"
      form.save_draft!
    end

    it "discards the draft" do
      expect {
        revert_draft_form_service.revert_draft_from_form_document(:live)
      }.to change { form.reload.draft_form_document_id }.to(nil)
    end

    it "keeps live content unchanged" do
      revert_draft_form_service.revert_draft_from_form_document(:live)
      expect(form.live_form_document.content.except("live_at")).to eq(live_content.except("live_at"))
    end
  end

  describe "when there is no draft" do
    let(:form) { create(:form, :live) }

    it "returns false" do
      expect(revert_draft_form_service.revert_draft_from_form_document(:live)).to be false
    end
  end
end
