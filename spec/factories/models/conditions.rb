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

    initialize_with do
      target_form = form || create(:form, :ready_for_live, routing_steps: true)
      resolved_routing_page = routing_page || target_form.pages.find { |p| p.id == routing_page_id } || target_form.pages.first
      resolved_check_page = check_page || (check_page_id && target_form.pages.find { |p| p.id == check_page_id }) || resolved_routing_page
      resolved_goto_page = goto_page || (goto_page_id && target_form.pages.find { |p| p.id == goto_page_id })

      condition = FormCondition.create_and_update_form!(
        form_id: target_form.id,
        routing_page_id: resolved_routing_page.id,
        check_page_id: resolved_check_page.id,
        goto_page_id: resolved_goto_page&.id,
        answer_value:,
        skip_to_end:,
        exit_page_heading:,
        exit_page_markdown:,
      )
      target_form.reload
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
