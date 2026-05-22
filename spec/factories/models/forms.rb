FactoryBot.define do
  factory :form, class: "Form" do
    transient do
      sequence(:form_name) { |n| "Form #{n}" }
      name { nil }
      name_cy { nil }
      submission_email { Faker::Internet.email(domain: "example.gov.uk") }
      submission_type { "email" }
      submission_format { [] }
      privacy_policy_url { Faker::Internet.url(host: "gov.uk") }
      privacy_policy_url_cy { nil }
      support_email { nil }
      support_email_cy { nil }
      support_phone { nil }
      support_phone_cy { nil }
      support_url { nil }
      support_url_cy { nil }
      support_url_text { nil }
      support_url_text_cy { nil }
      what_happens_next_markdown { nil }
      what_happens_next_markdown_cy { nil }
      declaration_markdown { nil }
      declaration_markdown_cy { nil }
      payment_url { nil }
      payment_url_cy { nil }
      available_languages { %w[en] }
      pages_count { 0 }
      pages { nil }
      state { nil }
      lifecycle { nil }
      routing_steps { false }
      send_copy_of_answers { "disabled" }
    end

    question_section_completed { false }
    declaration_section_completed { false }
    share_preview_completed { false }
    creator_id { nil }
    external_id { nil }
    welsh_completed { false }

    after(:create) do |form, evaluator|
      FormDocumentFactoryHelpers.apply_form_content!(
        form,
        name: evaluator.name.presence || evaluator.form_name,
        name_cy: evaluator.name_cy,
        submission_email: evaluator.submission_email,
        submission_type: evaluator.submission_type,
        submission_format: evaluator.submission_format,
        privacy_policy_url: evaluator.privacy_policy_url,
        privacy_policy_url_cy: evaluator.privacy_policy_url_cy,
        support_email: evaluator.support_email,
        support_email_cy: evaluator.support_email_cy,
        support_phone: evaluator.support_phone,
        support_phone_cy: evaluator.support_phone_cy,
        support_url: evaluator.support_url,
        support_url_cy: evaluator.support_url_cy,
        support_url_text: evaluator.support_url_text,
        support_url_text_cy: evaluator.support_url_text_cy,
        what_happens_next_markdown: evaluator.what_happens_next_markdown,
        what_happens_next_markdown_cy: evaluator.what_happens_next_markdown_cy,
        declaration_markdown: evaluator.declaration_markdown,
        declaration_markdown_cy: evaluator.declaration_markdown_cy,
        payment_url: evaluator.payment_url,
        payment_url_cy: evaluator.payment_url_cy,
        available_languages: evaluator.available_languages,
        send_copy_of_answers: evaluator.send_copy_of_answers,
      )

      if evaluator.routing_steps
        steps = (1..5).map do |i|
          FormDocumentFactoryHelpers.build_step_attrs(
            position: i,
            answer_type: "selection",
            answer_settings: { "only_one_option" => "true", "selection_options" => [{ "name" => "Option 1" }, { "name" => "Option 2" }] },
          )
        end
        steps.each_with_index { |s, i| s["next_step_id"] = steps[i + 1]&.dig("id") }
        hash = form.draft_content_service.content_hash
        hash["steps"] = steps
        hash["start_page"] = steps.first["id"]
        FormDocumentOperationsService.new(form).save_draft_content!(hash)
      elsif evaluator.pages_count.positive?
        FormDocumentFactoryHelpers.add_steps_to_form!(form, count: evaluator.pages_count)
      elsif evaluator.pages.present?
        form.pages = evaluator.pages
      end

      lifecycle = evaluator.lifecycle || evaluator.state
      FormDocumentFactoryHelpers.apply_lifecycle_state!(form, lifecycle) if lifecycle.present?
    end

    trait :with_group do
      transient do
        group { nil }
      end

      after(:build) do |form, evaluator|
        g = evaluator.group || FactoryBot.create(:group)
        form.instance_variable_set(:@associated_group, g)
        form.define_singleton_method(:group) { g }
      end

      after(:create) do |form, _evaluator|
        g = form.instance_variable_get(:@associated_group)
        GroupForm.create!(form_id: form.id, group_id: g.id) unless GroupForm.exists?(form_id: form.id, group_id: g.id)
      end
    end

    trait :new_form do
      submission_email { "" }
      privacy_policy_url { "" }
      pages_count { 0 }
    end

    trait :with_id do
      sequence(:id) { |n| n }
    end

    trait :with_pages do
      pages_count { 5 }
      question_section_completed { true }
    end

    trait :with_text_page do
      pages_count { 1 }

      after(:create) do |form, _evaluator|
        hash = form.draft_content_service.content_hash
        hash["steps"] = [
          FormDocumentFactoryHelpers.build_step_attrs(
            answer_type: "text",
            answer_settings: { input_type: %w[single_line long_text].sample },
          ),
        ]
        hash["start_page"] = hash["steps"].first["id"]
        FormDocumentOperationsService.new(form).save_draft_content!(hash)
      end

      question_section_completed { true }
    end

    trait :ready_for_live do
      with_pages
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
      what_happens_next_markdown { "We usually respond to applications within 10 working days." }
      question_section_completed { true }
      declaration_section_completed { true }
      share_preview_completed { true }
    end

    trait :with_submission_email do
      association :form_submission_email
    end

    trait :live do
      ready_for_live
      first_made_live_at { Time.zone.now }
      lifecycle { :live }
    end

    trait :live_with_draft do
      ready_for_live
      first_made_live_at { Time.zone.now }
      lifecycle { :live_with_draft }
    end

    trait :archived do
      ready_for_live
      first_made_live_at { Time.zone.now }
      lifecycle { :archived }
    end

    trait :archived_with_draft do
      ready_for_live
      first_made_live_at { Time.zone.now }
      lifecycle { :archived_with_draft }
    end

    trait :with_support do
      support_email { Faker::Internet.email(domain: "example.gov.uk") }
    end

    trait :ready_for_routing do
      routing_steps { true }
    end

    trait :missing_pages do
      ready_for_live
      question_section_completed { false }
      pages_count { 0 }
    end

    trait :with_welsh_translation do
      available_languages { %w[en cy] }
      welsh_completed { true }

      after(:create) do |form, evaluator|
        hash = form.draft_content_service.content_hash
        hash["name"] ||= { "en" => evaluator.name.presence || evaluator.form_name }
        hash["name"]["cy"] = "Welsh #{hash['name']['en']}"
        hash["available_languages"] = %w[en cy]

        %w[privacy_policy_url support_email support_phone support_url support_url_text declaration_markdown what_happens_next_markdown payment_url].each do |field|
          next unless hash[field].is_a?(Hash) && hash[field]["en"].present?

          hash[field]["cy"] = FormDocumentFactoryHelpers.welsh_value_for_field(field, hash[field]["en"])
        end

        Array(hash["steps"]).each do |step|
          %w[question_text hint_text page_heading guidance_markdown].each do |key|
            next unless step[key].is_a?(Hash) && step[key]["en"].present?

            step[key]["cy"] = "Welsh #{step[key]['en']}"
          end
        end

        FormDocumentOperationsService.new(form).save_draft_content!(hash)
      end
    end
  end
end
