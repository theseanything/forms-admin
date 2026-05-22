# frozen_string_literal: true

require "rails_helper"

RSpec.describe WelshChangeDetectionService do
  describe "#update_welsh?" do
    it "returns false when Welsh is not enabled" do
      form = create(:form, :live, available_languages: %w[en])
      expect(described_class.new(form).update_welsh?).to be false
    end

    it "returns false when live and draft content match after creating draft from live" do
      form = create(:form, :live, available_languages: %w[en], pages_count: 1)
      FormDocumentOperationsService.new(form).ensure_draft!
      form.reload
      expect(described_class.new(form).update_welsh?).to be false
    end

    it "returns true when a new step is added to draft" do
      form = create(:form, :live, available_languages: %w[en cy], pages_count: 1)
      FormDocumentOperationsService.new(form).ensure_draft!
      form.draft_content_service.add_step!(question_text: { "en" => "New question" }, answer_type: "text")
      form.reload
      expect(described_class.new(form).update_welsh?).to be true
    end
  end

  describe "#changes" do
    it "returns empty when Welsh is not enabled" do
      form = create(:form, :live, available_languages: %w[en])
      expect(described_class.new(form).changes).to eq([])
    end

    it "detects a new step without Welsh translation" do
      form = create(:form, :live, available_languages: %w[en cy], pages_count: 1)
      live_step_id = form.live_form_document.content["steps"].first["id"]
      FormDocumentOperationsService.new(form).ensure_draft!
      new_step = form.draft_content_service.add_step!(question_text: { "en" => "New question" }, answer_type: "text")
      changes = described_class.new(form).changes
      expect(changes).to include(hash_including(type: :new_page, page_id: new_step.id))
    end

    it "detects new form field needing Welsh translation" do
      form = create(:form, :live_with_draft, available_languages: %w[en cy])
      hash = form.draft_content_service.content_hash
      hash["payment_url"] = { "en" => "https://pay.example.gov.uk" }
      FormDocumentOperationsService.new(form).save_draft_content!(hash)
      changes = described_class.new(form).changes
      expect(changes).to include(hash_including(type: :new_field, field: :payment_url, scope: :form))
    end
  end
end
