# FormStep stand-in for legacy :page factory
FactoryBot.define do
  factory :page do
    skip_create

    transient do
      form { create(:form) }
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

    initialize_with do |evaluator|
      form = evaluator.form
      hash = form.draft_content_service.content_hash
      position = evaluator.position || hash["steps"].length + 1
      step = FormDocumentFactoryHelpers.build_step_attrs(
        position:,
        question_text: evaluator.question_text,
        answer_type: evaluator.answer_type,
        is_optional: evaluator.is_optional,
        is_repeatable: evaluator.is_repeatable,
        answer_settings: evaluator.answer_settings,
        hint_text: evaluator.hint_text,
        page_heading: evaluator.page_heading,
        guidance_markdown: evaluator.guidance_markdown,
        routing_conditions: evaluator.routing_conditions,
      )
      hash["steps"] ||= []
      hash["steps"] << step
      hash["steps"].sort_by! { |s| s["position"] }
      hash["steps"].each_with_index { |s, i| s["position"] = i + 1; s["next_step_id"] = hash["steps"][i + 1]&.dig("id") }
      hash["start_page"] = hash["steps"].first["id"]
      FormDocumentOperationsService.new(form).save_draft_content!(hash)
      FormStep.new(form:, step_data: step, draft_service: form.draft_content_service)
    end

    trait :with_hints do
      hint_text { Faker::Quote.yoda.truncate(500) }
    end

    trait :with_guidance do
      page_heading { Faker::Quote.yoda.truncate(250) }
      guidance_markdown { "## List of items \n\n\n #{Faker::Markdown.ordered_list}" }
    end

    trait :with_selection_settings do
      answer_type { "selection" }
      answer_settings { { "only_one_option" => "true", "selection_options" => [{ "name" => "Option 1" }, { "name" => "Option 2" }] } }
    end

    trait :with_text_settings do
      answer_type { "text" }
      answer_settings { { "input_type" => "single_line" } }
    end

    trait :with_file_upload_answer_type do
      answer_type { "file" }
    end
  end
end
