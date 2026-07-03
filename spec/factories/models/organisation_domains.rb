FactoryBot.define do
  factory :organisation_domain do
    organisation { association :organisation, id: 1, slug: "test-org" }
    domain { Faker::Internet.domain_name }
  end
end
