# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form, type: :model do
  let(:current_user) { build :user }

  describe "factory" do
    it "has a valid factory" do
      expect(create(:form)).to be_valid
    end

    it "has a live trait" do
      form = create :form, :live
      expect(form.state).to eq "live"
      expect(form.live_form_document).to be_present
    end

    it "has a live with draft trait" do
      form = create :form, :live_with_draft
      expect(form.state).to eq "live_with_draft"
    end

    it "has an archived trait" do
      form = create :form, :archived
      expect(form.state).to eq "archived"
    end

    it "has an archived with draft trait" do
      form = create :form, :archived_with_draft
      expect(form.state).to eq "archived_with_draft"
    end

    it "has a ready for routing trait" do
      form = create :form, :ready_for_routing
      expect(form.pages).to be_present
      expect(form.pages.map(&:position)).to eq [1, 2, 3, 4, 5]
    end

    describe "task status traits" do
      before do
        form.set_task_status_service(TaskStatusService.new(form:, current_user:))
      end

      describe "ready for live trait" do
        let(:form) { create :form, :ready_for_live, :with_group }

        it "creates a form that is ready to be made live" do
          expect(form.all_ready_for_live?).to be true
          expect(form.all_incomplete_tasks).to be_empty
        end
      end

      describe "missing pages trait" do
        let(:form) { create :form, :missing_pages }

        it "creates a form with missing pages" do
          form.set_task_status_service(TaskStatusService.new(form:, current_user:))
          expect(form.pages).to be_empty
          expect(form.all_incomplete_tasks).to include(:missing_pages)
        end
      end
    end
  end

  describe "send_copy_of_answers" do
    it "stores the value in draft content" do
      form = create(:form)
      form.send_copy_of_answers = "enabled"
      expect(form.draft_form_document.content["send_copy_of_answers"]).to eq("enabled")
    end
  end

  describe "form_slug" do
    let(:form) { create(:form, name: "My Test Form") }

    it "derives a slug from the name when saving draft content" do
      form.name = "Updated Form Name"
      form.save_draft!
      expect(form.form_slug).to eq("updated-form-name")
    end
  end

  describe "translations" do
    let(:form) { create(:form, available_languages: %w[en cy]) }

    it "stores and reads Welsh name on draft content" do
      form.name_cy = "Ffurflen"
      form.reload
      expect(form.name(locale: :cy)).to eq("Ffurflen")
    end
  end

  describe "external_id" do
    it "sets external_id to id after create" do
      form = create(:form)
      expect(form.external_id.to_s).to eq(form.id.to_s)
    end
  end

  describe "lifecycle and document pointers" do
    it "creates an initial draft document on create" do
      form = create(:form)
      expect(form.draft_form_document).to be_present
      expect(form.draft_form_document.content["steps"]).to eq([])
    end

    describe "live_form_document" do
      it "is nil for draft-only forms" do
        form = create(:form)
        expect(form.live_form_document).to be_nil
      end

      it "is present after publish" do
        form = create(:form, :live)
        expect(form.live_form_document).to be_present
        expect(form.live_form_document.readonly?).to be true
      end
    end

    describe "archived_form_document" do
      it "returns live document when archived" do
        form = create(:form, :archived)
        expect(form.archived_form_document).to eq(form.live_form_document)
      end
    end

    describe "welsh document accessors" do
      let(:form) { create(:form, :live, available_languages: %w[en cy]) }

      it "returns live document for welsh when cy is enabled" do
        expect(form.live_welsh_form_document).to eq(form.live_form_document)
      end

      it "returns nil for welsh when cy is not enabled" do
        en_only = create(:form, :live, available_languages: %w[en])
        expect(en_only.live_welsh_form_document).to be_nil
      end
    end
  end

  describe "#make_live!" do
    let(:form) { create(:form, :ready_for_live) }

    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    it "publishes draft to a new live document" do
      draft_id = form.draft_form_document_id
      form.make_live!
      form.reload
      expect(form.live_form_document_id).to be_present
      expect(form.draft_form_document_id).to be_nil
      expect(form.live_form_document_id).not_to eq(draft_id)
    end

    it "sets first_made_live_at on first publish" do
      expect {
        form.make_live!
        form.reload
      }.to change(form, :first_made_live_at).from(nil)
    end
  end

  describe "#archive_live_form!" do
    let(:form) { create(:form, :live) }

    it "archives the form and clears draft" do
      form.archive_live_form!
      form.reload
      expect(form.archived?).to be true
      expect(form.draft_form_document_id).to be_nil
    end
  end

  describe "#save_question_changes!" do
    let(:form) { create(:form, :with_pages, pages_count: 1) }

    it "persists step changes to draft document" do
      page = form.pages.first
      page.assign_attributes(question_text: "Updated question")
      page.save_and_update_form
      form.reload
      expect(form.draft_form_document.content["steps"].first.dig("question_text", "en")).to eq("Updated question")
    end
  end

  describe "#save_draft!" do
    let(:form) { create(:form, :live) }

    it "creates a draft from live when publishing changes on a live form" do
      form.save_draft!
      form.reload
      expect(form.live_with_draft?).to be true
    end
  end

  describe "version flags" do
    it "#has_draft_version is true for draft and live_with_draft" do
      expect(create(:form).has_draft_version).to be true
      expect(create(:form, :live_with_draft).has_draft_version).to be true
    end

    it "#has_live_version is true for live forms" do
      expect(create(:form, :live).has_live_version).to be true
      expect(create(:form).has_live_version).to be false
    end

    it "#has_been_archived is true for archived forms" do
      expect(create(:form, :archived).has_been_archived).to be true
    end
  end

  describe "#can_make_language_live?" do
    let(:form) { create(:form, :ready_for_live) }

    before do
      form.set_task_status_service(TaskStatusService.new(form:, current_user:))
    end

    it "allows English publish from draft when ready" do
      expect(form.can_make_language_live?(language: "en")).to be true
    end

    it "does not allow Welsh publish from draft-only form" do
      expect(form.can_make_language_live?(language: "cy")).to be false
    end
  end

  describe "#normalise_welsh!" do
    let(:form) { create(:form, :with_pages, pages_count: 1, available_languages: %w[en cy]) }

    it "clears Welsh step text when English question text is blank" do
      page = form.pages.first
      page.question_text_cy = "Cwestiwn"
      form.draft_content_service.update_step!(page.id, "question_text" => { "en" => "", "cy" => "Cwestiwn" })
      form.normalise_welsh!
      expect(form.pages.first.question_text_cy).to be_blank
    end
  end

  describe "#draft_created?" do
    let(:form) { create(:form, :live) }

    it "returns true when moving from live to live_with_draft" do
      form.create_draft_from_live_form!
      expect(form.draft_created?(:live)).to be true
    end
  end

  describe "#file_upload_question_count" do
    it "counts file upload steps" do
      form = create(:form)
      step = FormDocumentFactoryHelpers.build_step_attrs(answer_type: "file")
      hash = form.draft_content_service.content_hash
      hash["steps"] = [step]
      FormDocumentOperationsService.new(form).save_draft_content!(hash)
      expect(form.file_upload_question_count).to eq(1)
    end
  end

  describe "#destroy" do
    let!(:form) { create(:form, :with_group) }

    it "destroys the form and group association" do
      expect { form.destroy }.to change(Form, :count).by(-1)
    end
  end
end
