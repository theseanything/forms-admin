# frozen_string_literal: true

require "rails_helper"

RSpec.describe FormCopyService do
  let(:group) { create(:group) }
  let(:source_form) { create(:form, :live_with_draft, :with_pages, pages_count: 3) }
  let(:logged_in_user) { create(:user) }
  let(:tag) { "live" }
  let(:copied_form) { described_class.new(source_form, logged_in_user).copy(tag:) }

  before do
    GroupForm.create!(form: source_form, group: group)
  end

  describe "#copy" do
    it "creates a new form" do
      expect(copied_form).to be_a(Form)
      expect(copied_form).to be_persisted
      expect(copied_form.id).not_to eq(source_form.id)
    end

    it "sets the creator as the logged in user" do
      expect(copied_form.creator_id).to eq(logged_in_user.id)
    end

    it "has a reference to the original form" do
      expect(copied_form.copied_from_id).to eq(source_form.id)
    end

    it "copies and updates the name of the copy" do
      expect(copied_form.name).to eq("Copy of #{source_form.name}")
    end

    it "associates the draft form document with the new form" do
      expect(copied_form.draft_form_document.form).to eq(copied_form)
    end

    it "copies steps into draft document content" do
      expect(copied_form.draft_form_document.content["steps"].count).to eq(source_form.live_form_document.content["steps"].count)
    end

    it "creates new step ids in the copy" do
      source_ids = source_form.live_form_document.content["steps"].map { |s| s["id"] }
      copied_ids = copied_form.draft_form_document.content["steps"].map { |s| s["id"] }
      expect(copied_ids).not_to include(*source_ids)
    end

    it "resets task completion flags" do
      source_form.update!(question_section_completed: true, declaration_section_completed: true, share_preview_completed: true, welsh_completed: true)
      expect(copied_form.question_section_completed).to be false
      expect(copied_form.welsh_completed).to be false
    end

    it "places the copied form in the same group" do
      expect(copied_form.group).to eq(source_form.group)
    end

    context "when copying from draft" do
      let(:tag) { "draft" }
      let(:source_form) { create(:form, :with_pages, pages_count: 2) }

      it "creates a draft-only copy" do
        expect(copied_form.state).to eq("draft")
        expect(copied_form.draft_form_document).to be_present
      end
    end

    context "when source has Welsh translations" do
      let(:source_form) do
        create(:form, :ready_for_live, pages_count: 1, available_languages: %w[en cy]).tap do |f|
          f.name_cy = "Ffurflen"
          hash = f.draft_content_service.content_hash
          hash["steps"].first["question_text"]["cy"] = "Cwestiwn"
          FormDocumentOperationsService.new(f).save_draft_content!(hash)
          FormDocumentFactoryHelpers.publish_form!(f)
          f.update!(welsh_completed: true)
          f.reload
        end
      end

      it "copies Welsh content in document" do
        expect(copied_form.name(locale: :cy)).to eq("Copy of Ffurflen")
        expect(copied_form.pages.first.question_text_cy).to eq("Cwestiwn")
      end
    end

    context "when copy fails" do
      it "returns false and does not persist a partial copy" do
        allow(FormDocumentOperationsService).to receive(:new).and_raise(ActiveRecord::RecordInvalid.new(Form.new))
        result = described_class.new(source_form, logged_in_user).copy(tag: "live")
        expect(result).to be false
        expect(Form.where(copied_from_id: source_form.id)).to be_empty
      end
    end
  end
end
