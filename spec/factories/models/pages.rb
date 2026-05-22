# FormStep stand-in for legacy :page factory
FactoryBot.define do
  factory :page, class: "FormStep" do
    skip_create

    transient do
      id { nil }
      form { nil }
      question_text { Faker::Lorem.question.truncate(250) }
      answer_type { FormStep::ANSWER_TYPES_WITHOUT_SETTINGS.sample }
      is_optional { false }
      is_repeatable { false }
      answer_settings { nil }
      hint_text { nil }
      position { nil }
      page_heading { nil }
      guidance_markdown { nil }
      routing_conditions { [] }
    end

    initialize_with do
      target_form = form || create(:form)
      hash = target_form.draft_content_service.content_hash
      position = self.position || hash["steps"].length + 1
      step = FormDocumentFactoryHelpers.build_step_attrs(
        position:,
        question_text:,
        answer_type:,
        is_optional:,
        is_repeatable:,
        answer_settings: normalize_answer_settings(answer_settings),
        hint_text:,
        page_heading:,
        guidance_markdown:,
        routing_conditions:,
      )
      step["id"] = id.to_s if id.present?
      hash["steps"] ||= []
      hash["steps"] << step
      hash["steps"].sort_by! { |s| s["position"] }
      hash["steps"].each_with_index { |s, i| s["position"] = i + 1; s["next_step_id"] = hash["steps"][i + 1]&.dig("id") }
      hash["start_page"] = hash["steps"].first["id"]
      FormDocumentOperationsService.new(target_form).save_draft_content!(hash)
      target_form.reload
      FormStep.new(form: target_form, step_data: step, draft_service: target_form.draft_content_service)
    end

    trait :with_hints do
      hint_text { Faker::Quote.yoda.truncate(500) }
    end

    trait :with_guidance do
      page_heading { Faker::Quote.yoda.truncate(250) }
      guidance_markdown { "## List of items \n\n\n #{Faker::Markdown.ordered_list}" }
    end

    trait :with_simple_answer_type do
      answer_type { FormStep::ANSWER_TYPES_WITHOUT_SETTINGS.sample }
    end

    trait :with_selection_settings do
      transient do
        only_one_option { "true" }
        selection_options { [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }] }
      end

      answer_type { "selection" }
      answer_settings { { "only_one_option" => only_one_option, "selection_options" => selection_options } }
    end

    trait :selection_with_radios do
      answer_type { "selection" }
      answer_settings do
        {
          "only_one_option" => "true",
          "selection_options" => (1..30).to_a.map { |i| { "name" => i.to_s, "value" => i.to_s } },
        }
      end
    end

    trait :selection_with_autocomplete do
      answer_type { "selection" }
      answer_settings do
        {
          "only_one_option" => "true",
          "selection_options" => (1..31).to_a.map { |i| { "name" => i.to_s, "value" => i.to_s } },
        }
      end
    end

    trait :selection_with_checkboxes do
      answer_type { "selection" }
      answer_settings do
        {
          "only_one_option" => "false",
          "selection_options" => [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }],
        }
      end
    end

    trait :selection_with_none_of_the_above_question do
      transient do
        only_one_option { "true" }
        selection_options { [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }] }
        none_of_the_above_question_text { "None of the above question?" }
        none_of_the_above_question_is_optional { "true" }
      end

      answer_type { "selection" }
      is_optional { true }
      answer_settings do
        {
          "only_one_option" => only_one_option,
          "selection_options" => selection_options,
          "none_of_the_above_question" => {
            "question_text" => { "en" => none_of_the_above_question_text },
            "is_optional" => none_of_the_above_question_is_optional,
          },
        }
      end
    end

    trait :with_text_settings do
      transient do
        input_type { "single_line" }
      end

      answer_type { "text" }
      answer_settings { { "input_type" => input_type } }
    end

    trait :with_single_line_text_settings do
      answer_type { "text" }
      answer_settings { { "input_type" => "single_line" } }
    end

    trait :with_date_settings do
      transient do
        input_type { "date_of_birth" }
      end

      answer_type { "date" }
      answer_settings { { "input_type" => input_type } }
    end

    trait :with_address_settings do
      transient do
        uk_address { "true" }
        international_address { "true" }
      end

      answer_type { "address" }
      answer_settings do
        {
          "input_type" => {
            "uk_address" => uk_address,
            "international_address" => international_address,
          },
        }
      end
    end

    trait :with_name_settings do
      transient do
        input_type { "full_name" }
        title_needed { "false" }
      end

      answer_type { "name" }
      answer_settings { { "input_type" => input_type, "title_needed" => title_needed } }
    end

    trait :with_full_name_settings do
      answer_type { "name" }
      answer_settings { { "input_type" => "full_name", "title_needed" => "false" } }
    end

    trait :with_file_upload_answer_type do
      answer_type { "file" }
    end
  end
end

def normalize_answer_settings(settings)
  return settings if settings.nil? || settings.is_a?(Hash)

  settings.respond_to?(:to_h) ? settings.to_h.stringify_keys : settings
end
