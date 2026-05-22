# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormDocumentOperationsService do
  let(:current_user) { build(:user) }
  let(:form) { create(:form, :ready_for_live) }
  let(:service) { described_class.new(form) }

  before do
    form.set_task_status_service(TaskStatusService.new(form:, current_user:))
  end

  describe "#publish!" do
    it "creates a new live document and clears draft pointer" do
      draft_id = form.draft_form_document_id
      service.publish!
      form.reload
      expect(form.live_form_document_id).to be_present
      expect(form.draft_form_document_id).to be_nil
      expect(form.live_form_document.supersedes_id).to be_nil
      expect(FormDocument.exists?(draft_id)).to be true
    end
  end

  describe "#ensure_draft!" do
    let(:form) { create(:form, :live) }

    it "copies live content into a new draft" do
      service.ensure_draft!
      form.reload
      expect(form.draft_form_document).to be_present
      expect(form.draft_form_document.content["name"]).to eq(form.live_form_document.content["name"])
    end
  end

  describe "#discard_draft!" do
    let(:form) { create(:form, :live_with_draft) }

    it "removes the draft pointer and document" do
      draft_id = form.draft_form_document_id
      service.discard_draft!
      form.reload
      expect(form.draft_form_document_id).to be_nil
      expect(FormDocument.exists?(draft_id)).to be false
    end
  end

  describe "#archive!" do
    let(:form) { create(:form, :live) }

    it "marks form archived and removes draft" do
      service.archive!
      form.reload
      expect(form.archived?).to be true
      expect(form.draft_form_document_id).to be_nil
    end
  end
end
