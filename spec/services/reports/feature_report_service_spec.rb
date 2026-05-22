require "rails_helper"

RSpec.describe Reports::FeatureReportService do
  let(:forms) do
    [
      form_with_all_answer_types,
      form_with_a_few_answer_types,
      branch_route_form,
      basic_route_form,
      copied_form,
      form_with_a_welsh_translation,
    ]
  end
  let(:form_documents) do
    forms.map do |form|
      report_form_document_for(form)
    end
  end

  def report_form_document_for(form)
    JSON.parse(
      FormDocumentFactoryHelpers.report_form_document_json(form).merge(
        "welsh_completed" => form.welsh_completed,
      ).to_json,
    )
  end
  let(:group) { create(:group) }

  let(:form_with_all_answer_types) do
    form = create(:form, :ready_for_live, :with_support, pages_count: 0, submission_type: "email", submission_format: %w[csv], payment_url: "https://www.gov.uk/payments/organisation/service")
    [
      create(:page, :with_address_settings, form:, is_repeatable: true),
      create(:page, :with_date_settings, form:),
      create(:page, form:, answer_type: "email"),
      create(:page, :with_full_name_settings, form:),
      create(:page, form:, answer_type: "national_insurance_number"),
      create(:page, form:, answer_type: "number"),
      create(:page, form:, answer_type: "phone_number"),
      create(:page, :with_selection_settings, form:, is_optional: true),
      create(:page, :with_single_line_text_settings, form:, is_repeatable: true),
    ]
    FormDocumentFactoryHelpers.publish_form!(form)
    form.reload
  end
  let(:form_with_a_few_answer_types) do
    form = create(:form, :ready_for_live, submission_type: "email", submission_format: %w[csv json], send_daily_submission_batch: true, send_weekly_submission_batch: true)
    create(:page, form:, answer_type: "email")
    create_list(:page, 3, form:, answer_type: "name")
    FormDocumentFactoryHelpers.publish_form!(form)
    form.reload
  end
  let(:branch_route_form) do
    form = create(:form, :ready_for_live, routing_steps: true, submission_type: "s3", submission_format: %w[csv])
    create(:condition, :with_exit_page, form:, routing_page_id: form.pages[0].id, check_page_id: form.pages[0].id, answer_value: "Option 1")
    create(:condition, form:, routing_page_id: form.pages[1].id, check_page_id: form.pages[1].id, answer_value: "Option 1", goto_page_id: form.pages[3].id)
    create(:condition, form:, routing_page_id: form.pages[2].id, check_page_id: form.pages[1].id, goto_page_id: form.pages[4].id)
    FormDocumentFactoryHelpers.publish_form!(form)
    form.reload
  end
  let(:basic_route_form) do
    form = create(:form, :ready_for_live, routing_steps: true)
    create(:condition, form:, routing_page_id: form.pages.first.id, check_page_id: form.pages.first.id, answer_value: "Option 1", skip_to_end: true)
    FormDocumentFactoryHelpers.publish_form!(form)
    form.reload
  end
  let(:copied_form) do
    original_form = create(:form, :live)
    form = create(:form, :live)
    FormDocumentFactoryHelpers.set_copied_from_on_documents!(form, original_form.id)
    form.reload
  end
  let(:form_with_a_welsh_translation) do
    create(:form, :live, :with_welsh_translation)
  end

  before do
    forms.each do |form|
      GroupForm.create!(form: form, group: group)
    end
  end

  describe "#report" do
    it "returns the feature report" do
      report = described_class.new(form_documents).report
      expect(report[:total_forms]).to eq(6)
      expect(report[:copied_forms]).to eq(1)
      expect(report[:forms_with_payment]).to eq(1)
      expect(report[:forms_with_routing]).to eq(2)
      expect(report[:forms_with_branch_routing]).to eq(1)
      expect(report[:forms_with_add_another_answer]).to eq(1)
      expect(report[:forms_with_csv_submission_email_attachments]).to eq(2)
      expect(report[:forms_with_json_submission_email_attachments]).to eq(1)
      expect(report[:forms_with_daily_submission_csv]).to eq(1)
      expect(report[:forms_with_weekly_submission_csv]).to eq(1)
      expect(report[:forms_with_s3_submissions]).to eq(1)
      expect(report[:forms_with_exit_pages]).to eq(1)
      expect(report[:forms_with_welsh_translation]).to eq(1)
      expect(report[:steps_with_answer_type]["selection"]).to eq(11)
      expect(report[:forms_with_answer_type]["selection"]).to eq(3)
    end
  end

  describe "#questions" do
    it "returns all questions in all forms given" do
      questions = described_class.new(form_documents).questions
      expect(questions.length).to be >= 23
    end

    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions
      expect(questions).to all match(
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => an_instance_of(Integer),
            "content" => a_hash_including(
              "name" => a_kind_of(String),
            ),
          ),
          "data" => a_hash_including(
            "question_text" => a_kind_of(String),
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "#questions_with_answer_type" do
    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions_with_answer_type("email")
      expect(questions).to include(
        a_hash_including(
          "form" => a_hash_including("form_id" => form_with_all_answer_types.id),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages.find { |p| p.answer_type == "email" }.question_text,
          ),
        ),
        a_hash_including(
          "form" => a_hash_including("form_id" => form_with_a_few_answer_types.id),
          "data" => a_hash_including(
            "question_text" => form_with_a_few_answer_types.pages.find { |p| p.answer_type == "email" }.question_text,
          ),
        ),
      )
    end

    it "returns questions with the given answer type" do
      questions = described_class.new(form_documents).questions_with_answer_type("name")
      expect(questions.length).to eq 4
      expect(questions).to all match(
        a_hash_including(
          "data" => a_hash_including(
            "answer_type" => "name",
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "#questions_with_add_another_answer" do
    it "returns details needed to render report" do
      questions = described_class.new(form_documents).questions_with_add_another_answer
      expect(questions).to contain_exactly(
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_all_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_all_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages[0].question_text,
          ),
        ),
        a_hash_including(
          "form" => a_hash_including(
            "form_id" => form_with_all_answer_types.id,
            "content" => a_hash_including(
              "name" => form_with_all_answer_types.name,
            ),
          ),
          "data" => a_hash_including(
            "question_text" => form_with_all_answer_types.pages[8].question_text,
          ),
        ),
      )
    end

    it "returns questions with add another answer" do
      questions = described_class.new(form_documents).questions_with_add_another_answer
      expect(questions).to all match(
        a_hash_including(
          "data" => a_hash_including(
            "is_repeatable" => true,
          ),
        ),
      )
    end

    it "includes a reference to the form document" do
      questions = described_class.new(form_documents).questions_with_answer_type("text")
      expect(questions).to all include(
        "form" => a_hash_including(
          "form_id",
          "content" => a_hash_including(
            "name",
          ),
        ),
      )
    end
  end

  describe "selection questions methods" do
    let(:form_documents) do
      [report_form_document_for(form)]
    end
    let(:form) do
      f = create(:form, :ready_for_live, pages_count: 0)
      create(:page, :selection_with_checkboxes, form: f)
      create(:page, :selection_with_radios, form: f)
      create(:page, :selection_with_autocomplete, form: f)
      create(:page, form: f, answer_type: "name")
      FormDocumentFactoryHelpers.publish_form!(f)
      f.reload
    end
    let(:page_with_autocomplete) { form.pages.find { |p| p.answer_type == "selection" && p.answer_settings.selection_options.length > 30 } }
    let(:page_with_radios) { form.pages.find { |p| p.answer_type == "selection" && p.only_one_option? } }
    let(:page_with_checkboxes) { form.pages.find { |p| p.answer_type == "selection" && !p.only_one_option? } }
    let(:not_selection_question) { form.pages.find { |p| p.answer_type == "name" } }
    let(:forms) { [form] }

    describe "#selection_questions_with_autocomplete" do
      it "returns question with autocomplete" do
        questions = described_class.new(form_documents).selection_questions_with_autocomplete
        expect(questions.length).to eq(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_autocomplete.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end
    end

    describe "#selection_questions_with_radios" do
      it "returns question with radios" do
        questions = described_class.new(form_documents).selection_questions_with_radios
        expect(questions.length).to eq(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_radios.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end
    end

    describe "#selection_questions_with_checkboxes" do
      it "returns question with checkboxes" do
        questions = described_class.new(form_documents).selection_questions_with_checkboxes
        expect(questions.length).to eq(1)
        expect(questions.first["data"]["question_text"]).to eq(page_with_checkboxes.question_text)
        expect(questions.first["form"]["form_id"]).to eq(form.id)
      end

      # This ensures there is backwards compatibility for existing questions as we previously set "only_one_option" to
      # "0" rather than "false"
      context "when question has only_one_option value '0'" do
        before do
          page = form.pages.find { |p| p.answer_type == "selection" && !p.only_one_option? }
          hash = form.draft_content_service.content_hash
          step = hash["steps"].find { |s| s["id"] == page.id }
          step["data"]["answer_settings"]["only_one_option"] = "0"
          FormDocumentOperationsService.new(form).save_draft_content!(hash)
          FormDocumentFactoryHelpers.publish_form!(form)
          form.reload
        end

        it "returns question with checkboxes" do
          checkbox_page = form.pages.find { |p| p.answer_type == "selection" && !p.only_one_option? }
          questions = described_class.new(form_documents).selection_questions_with_checkboxes
          expect(questions.length).to eq(1)
          expect(questions.first["data"]["question_text"]).to eq(checkbox_page.question_text)
        end
      end
    end
  end

  describe "#selection_questions_with_none_of_the_above" do
    it "returns selection questions that include none of the above" do
      form = create(:form, :ready_for_live, pages_count: 0)
      create(:page, :selection_with_none_of_the_above_question, form:, is_optional: true)
      create(:page, :with_selection_settings, form:, is_optional: false)
      FormDocumentFactoryHelpers.publish_form!(form)
      form.reload
      form_document = FormDocumentFactoryHelpers.report_form_document_json(form)

      questions = described_class.new([form_document]).selection_questions_with_none_of_the_above
      expect(questions.length).to eq 1
      expect(questions.first["data"]["question_text"]).to eq(form.pages[0].question_text)
    end
  end

  describe "#forms_with_branch_routes" do
    it "returns details needed to render report" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
          "metadata" => {
            "number_of_routes" => 3,
            "number_of_branch_routes" => 1,
          },
        ),
      ]
    end

    it "returns forms with branch routes" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
        ),
      ]
    end

    it "includes counts of routes" do
      forms = described_class.new(form_documents).forms_with_branch_routes
      expect(forms).to all include(
        "metadata" => a_hash_including(
          "number_of_routes" => an_instance_of(Integer),
          "number_of_branch_routes" => an_instance_of(Integer),
        ),
      )
    end
  end

  describe "#forms_with_payments" do
    it "returns live forms with payments" do
      forms = described_class.new(form_documents).forms_with_payments
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_all_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_all_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_exit_pages" do
    it "returns live forms with payments" do
      forms = described_class.new(form_documents).forms_with_exit_pages
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name",
          ),
        ),
      ]
    end
  end

  describe "#forms_with_csv_submission_email_attachments" do
    it "returns live forms with csv enabled" do
      forms = described_class.new(form_documents).forms_with_csv_submission_email_attachments
      expect(forms.length).to eq 2
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_all_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_all_answer_types.name,
          ),
        ),
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_json_submission_email_attachments" do
    it "returns live forms with json enabled" do
      forms = described_class.new(form_documents).forms_with_json_submission_email_attachments
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_daily_submission_csv" do
    it "returns live forms with daily submission csv enabled" do
      forms = described_class.new(form_documents).forms_with_daily_submission_csv
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_weekly_submission_csv" do
    it "returns live forms with weekly submission csv enabled" do
      forms = described_class.new(form_documents).forms_with_weekly_submission_csv
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_few_answer_types.id,
          "content" => a_hash_including(
            "name" => form_with_a_few_answer_types.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_s3_submissions" do
    it "returns live forms with json enabled" do
      forms = described_class.new(form_documents).forms_with_s3_submissions
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => branch_route_form.id,
          "content" => a_hash_including(
            "name" => branch_route_form.name,
          ),
        ),
      ]
    end
  end

  describe "#forms_that_are_copies" do
    it "returns forms that are copies" do
      forms = described_class.new(form_documents).forms_that_are_copies
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => copied_form.id,
          "content" => a_hash_including(
            "name" => copied_form.name,
            "copied_from_id" => copied_form.copied_from_id,
          ),
        ),
      ]
    end
  end

  describe "#forms_with_welsh_translation" do
    it "returns live forms with welsh translation" do
      forms = described_class.new(form_documents).forms_with_welsh_translation
      expect(forms.length).to eq 1
      expect(forms).to match [
        a_hash_including(
          "form_id" => form_with_a_welsh_translation.id,
          "content" => a_hash_including(
            "name" => form_with_a_welsh_translation.name,
          ),
        ),
      ]
    end
  end
end

# TEMP
