FactoryBot.define do
  factory :route_input, class: "Forms::RouteInput" do
    transient do
      page { association :page }
      goto_page { association :page }
    end

    # Assign attributes based on the transient page object.
    page_id { page.id }
    answer_value { "Yes" }
    goto { goto_page.id }

    after(:build) do |route_input, evaluator|
      route_input.page = evaluator.page
      route_input.goto_page = evaluator.goto_page
    end

    trait :default do
      goto { Forms::RouteInput::DEFAULT_VALUE }
      goto_page { nil }
    end

    trait :check_your_answers do
      goto { Forms::RouteInput::END_OF_FORM_VALUE }
      goto_page { nil }
    end
  end
end
