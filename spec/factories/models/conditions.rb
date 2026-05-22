FactoryBot.define do
  factory :condition, class: "FormCondition" do
    skip_create

    transient do
      form { nil }
      routing_page { nil }
      check_page { nil }
      goto_page { nil }
      routing_page_id { nil }
      check_page_id { nil }
      goto_page_id { nil }
      answer_value { "Option 1" }
      skip_to_end { false }
      exit_page_heading { nil }
      exit_page_markdown { nil }
    end

    initialize_with do |evaluator, *_args|
      evaluator ||= OpenStruct.new
      form = evaluator.form || create(:form, :ready_for_live, routing_steps: true)
      routing_page = evaluator.routing_page || form.pages.find { |p| p.id == evaluator.routing_page_id } || form.pages.first
      check_page = evaluator.check_page || (evaluator.check_page_id && form.pages.find { |p| p.id == evaluator.check_page_id }) || routing_page
      goto_page = evaluator.goto_page || (evaluator.goto_page_id && form.pages.find { |p| p.id == evaluator.goto_page_id })

      condition = FormCondition.create_and_update_form!(
        form_id: form.id,
        routing_page_id: routing_page.id,
        check_page_id: check_page.id,
        goto_page_id: goto_page&.id,
        answer_value: evaluator.answer_value,
        skip_to_end: evaluator.skip_to_end,
        exit_page_heading: evaluator.exit_page_heading,
        exit_page_markdown: evaluator.exit_page_markdown,
      )
      form.reload
      condition
    end

    trait :with_exit_page do
      answer_value { "Option 1" }
      skip_to_end { false }
      goto_page_id { nil }
      exit_page_heading { { "en" => "Exit heading" } }
      exit_page_markdown { { "en" => "Exit body" } }
    end
  end
end
