FactoryBot.define do
  factory :form_document do
    association :form

    after(:build) do |doc|
      doc.content ||= {
        "form_id" => doc.form_id.to_s,
        "name" => { "en" => "Test form" },
        "available_languages" => %w[en],
        "steps" => [],
      }
    end

    trait :live do
      after(:create) do |doc|
        doc.form.update!(live_form_document_id: doc.id)
      end
    end

    trait :draft do
      after(:create) do |doc|
        doc.form.update!(draft_form_document_id: doc.id)
      end
    end
  end
end
