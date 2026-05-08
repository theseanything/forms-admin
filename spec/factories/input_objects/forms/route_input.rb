FactoryBot.define do
  factory :route_input, class: "Forms::RouteInput" do
    transient do
      page { association :page }
    end

    # Assign attributes based on the transient page object.
    page_id { page.id }
    answer_value { "Yes" }
    goto { build_stubbed(:page).id }

    after(:build) do |route_input, evaluator|
      route_input.page = evaluator.page
    end

    trait :default do
      goto { Forms::RouteInput::DEFAULT_VALUE }
    end

    trait :check_your_answers do
      goto { Forms::RouteInput::END_OF_FORM_VALUE }
    end
  end
end
