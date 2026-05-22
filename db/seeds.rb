# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if (HostingEnvironment.local_development? || HostingEnvironment.review?) && User.none?

  gds = Organisation.find_or_create_by!(
    govuk_content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9",
    slug: "government-digital-service",
    name: "Government Digital Service",
    abbreviation: "GDS",
  )

  # Create default super-admin
  default_user = User.create!({ email: "example@example.com",
                                organisation_slug: "government-digital-service",
                                organisation_content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9",
                                organisation: gds,
                                name: "A User",
                                role: :super_admin,
                                uid: "123456",
                                provider: :mock_gds_sso,
                                terms_agreed_at: Time.zone.now,
                                research_contact_status: :consented,
                                user_research_opted_in_at: Time.zone.now })

  MouSignature.create! user: default_user, organisation: gds, agreement_type: "crown"

  # create extra organisations
  test_org = Organisation.create! slug: "test-org", name: "Test Org", abbreviation: "TO"
  mot_org = Organisation.create! slug: "ministry-of-tests", name: "Ministry of Tests", abbreviation: "MOT"
  Organisation.create! slug: "department-for-testing", name: "Department for Testing", abbreviation: "DfT"
  Organisation.create! slug: "closed-org", name: "Closed Org", abbreviation: "CO", closed: true

  # create extra standard users
  User.create!(
    email: "phil@example.gov.uk",
    name: "Phil Mein",
    role: :standard,
    organisation: test_org,
    provider: :seed,
  )
  mot_user = User.create!(
    email: "subo@example.gov.uk",
    name: "Subo Mitt",
    role: :standard,
    organisation: mot_org,
    provider: :seed,
  )
  User.create!(
    email: "otto@example.gov.uk",
    name: "Otto Komplit",
    role: :standard,
    organisation: test_org,
    provider: :seed,
    research_contact_status: :consented,
    user_research_opted_in_at: Time.zone.now,
  )

  # create extra super admins
  craig = User.create!(
    email: "craig@example.gov.uk",
    name: "Craig",
    role: :super_admin,
    organisation: gds,
    created_at: Time.utc(2022, 3, 3, 9),
    last_signed_in_at: Time.utc(2022, 3, 3, 9),
    terms_agreed_at: Time.utc(2022, 3, 3, 9),
    provider: :seed,
  )
  User.create!(
    email: "bey@example.gov.uk",
    name: "Bey",
    role: :super_admin,
    organisation: gds,
    created_at: Time.utc(2023, 3, 11, 6, 26),
    last_signed_in_at: Time.utc(2023, 3, 11, 6, 26),
    terms_agreed_at: Time.utc(2023, 3, 11, 6, 26),
    provider: :seed,
  )
  User.create!(
    email: "taylor@example.gov.uk",
    name: "Taylor",
    role: :super_admin,
    organisation: gds,
    created_at: Time.utc(2024, 4, 22, 9, 30),
    last_signed_in_at: Time.utc(2024, 4, 22, 9, 30),
    terms_agreed_at: Time.utc(2024, 4, 22, 9, 30),
    provider: :seed,
    research_contact_status: :consented,
    user_research_opted_in_at: Time.utc(2024, 4, 22, 9, 30),
  )

  # while we're using Signon it is possible to have users who aren't linked to
  # the same organisation as in Signon, or who have an organisation that isn't
  # in the organisation table
  User.create!(
    email: "bakbert@example.gov.uk",
    name: "Bakber Tan",
    organisation_slug: test_org.slug,
    organisation_content_id: test_org.govuk_content_id,
    provider: :seed,
  )
  User.create!(
    email: "ckboxes@example.gov.uk",
    name: "Che K Boxes",
    organisation_slug: "unknown-org",
    organisation_content_id: "fb48187d-6a62-42e1-ab8e-cbb4205075ad",
    provider: :seed,
  )

  # create a user who hasn't been assigned to an organisation yet
  User.create!(
    email: "lez.philmore@example.gov.uk",
    name: "Lez Philmore",
    provider: :seed,
  )

  # create some standard users without name or organisation
  User.create!(email: "kezz.strel101@example.gov.uk", role: :standard, provider: :seed)
  User.create!(email: "lauramipsum@example.gov.uk", role: :standard, provider: :seed)
  User.create!(email: "chidi.anagonye@example.gov.uk", role: :standard, provider: :seed)

  # create some test groups
  end_to_end_group = Group.create! name: "End to end tests", organisation: gds, status: :active
  test_group = Group.create! name: "Test Group", organisation: gds, creator: default_user, status: :active
  multiple_branches_test_group = Group.create! name: "Test Group with multiple branches", organisation: gds, creator: default_user, status: :active, multiple_branches_enabled: true
  Group.create! name: "Ministry of Tests forms", organisation: mot_org
  Group.create! name: "Ministry of Tests forms - secret!", organisation: mot_org, creator: mot_user

  Membership.create! user: default_user, group: end_to_end_group, added_by: default_user, role: :group_admin

  submission_email = ENV["EMAIL"] || `git config --get user.email`.strip
  require Rails.root.join("db/seed_forms_helper")

  common_form_attrs = {
    submission_email:,
    support_email: "your.email+fakedata84701@gmail.com.gov.uk",
    support_phone: "08000800",
    what_happens_next_markdown: "Test",
  }

  all_question_types_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "All question types form",
    **common_form_attrs,
    steps: [
      { question_text: "Single line of text", answer_type: "text", answer_settings: { input_type: "single_line" } },
      { question_text: "Number", answer_type: "number" },
      { question_text: "Address", answer_type: "address", answer_settings: { uk_address: true, international_address: false } },
      { question_text: "Email address", answer_type: "email" },
      { question_text: "Todays Date", answer_type: "date", answer_settings: { input_type: "other_date" } },
      { question_text: "National Insurance number", answer_type: "national_insurance_number" },
      { question_text: "Phone number", answer_type: "phone_number" },
      { question_text: "Selection from a list of options", answer_type: "selection", is_optional: true, answer_settings: { only_one_option: "false", selection_options: [{ "name" => "Option 1", "value" => "Option 1" }, { "name" => "Option 2", "value" => "Option 2" }, { "name" => "Option 3", "value" => "Option 3" }] } },
      { question_text: "Multiple lines of text", answer_type: "text", is_optional: true, answer_settings: { input_type: "long_text" } },
    ],
  )

  e2e_s3_forms = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "s3 submission test form",
    **common_form_attrs,
    submission_type: "s3",
    submission_format: %w[csv],
    s3_bucket_region: "eu-west-2",
    steps: [
      { question_text: "Single line of text", answer_type: "text", answer_settings: { input_type: "single_line" } },
    ],
  )

  branch_route_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "Branch route form",
    **common_form_attrs,
    steps: [
      { question_text: "Are you eligible to submit this form?", answer_type: "selection", answer_settings: { only_one_option: "true", selection_options: [{ "name" => "Yes", "value" => "Yes" }, { "name" => "No", "value" => "No" }] } },
      { question_text: "How many times have you filled out this form?", answer_type: "selection", answer_settings: { only_one_option: "true", selection_options: [{ "name" => "Once", "value" => "Once" }, { "name" => "More than once", "value" => "More than once" }] } },
      { question_text: "What's your name?", answer_type: "name", answer_settings: { input_type: "full_name", title_needed: "false" } },
      { question_text: "What's your email address?", answer_type: "email" },
      { question_text: "What was the reference of your previous submission?", answer_type: "text", answer_settings: { input_type: "single_line" } },
      { question_text: "What's your answer?", answer_type: "text", answer_settings: { input_type: "single_line" } },
    ],
    conditions: [
      { routing_index: 1, check_index: 1, goto_index: 4, answer_value: "More than once" },
      { routing_index: 3, check_index: 1, goto_index: 5, answer_value: nil },
      { routing_index: 0, check_index: 0, goto_index: nil, answer_value: "No", exit_page_heading: "You are not eligible to submit this form", exit_page_markdown: "To complete this form you must:\n\n- Be over 16\n- Confirmed that you are eligible to submit this form" },
    ],
  )

  none_of_the_above_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "None of the above form",
    **common_form_attrs,
    steps: [
      { question_text: "Which option do you want?", answer_type: "selection", is_optional: true, answer_settings: { only_one_option: "true", selection_options: [{ "name" => "The first option", "value" => "The first option" }, { "name" => "The second option", "value" => "The second option" }], none_of_the_above_question: { question_text: { "en" => "What other option could you possibly want?" }, is_optional: "true" } } },
      { question_text: "What is your favourite number?", answer_type: "selection", is_optional: true, answer_settings: { only_one_option: "true", selection_options: (0..10).map { |n| { "name" => n.to_s, "value" => n.to_s } }, none_of_the_above_question: { question_text: { "en" => "Enter a number" }, is_optional: "false" } } },
    ],
  )

  welsh_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "A Welsh form",
    name_cy: "Ffurflen Gymraeg",
    available_languages: %w[en cy],
    welsh_completed: true,
    **common_form_attrs,
    steps: [
      { question_text: "What's your name?", question_text_cy: "Beth yw eich enw?", answer_type: "name", hint_text: "Enter your name as it appears on your licence.", hint_text_cy: "Rhowch eich enw fel y mae'n ymddangos ar eich trwydded.", answer_settings: { input_type: "full_name", title_needed: "false" } },
      { question_text: "What's your email address?", question_text_cy: "Beth yw eich cyfeiriad e-bost?", answer_type: "email" },
    ],
  )

  multiple_branch_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "Multiple branch form",
    **common_form_attrs,
    steps: [
      { question_text: "Do you currently live in the UK?", answer_type: "selection", answer_settings: { only_one_option: "true", selection_options: [{ "name" => "Yes", "value" => "Yes" }, { "name" => "No", "value" => "No" }] } },
      { question_text: "Where do you currently live?", answer_type: "selection", answer_settings: { only_one_option: "true", selection_options: [{ "name" => "England", "value" => "England" }, { "name" => "Scotland", "value" => "Scotland" }, { "name" => "Wales", "value" => "Wales" }, { "name" => "Northern Ireland", "value" => "Northern Ireland" }] } },
      { question_text: "How many years have you lived in England?", answer_type: "number" },
      { question_text: "How many years have you lived in Scotland?", answer_type: "number" },
      { question_text: "How many years have you lived in Wales?", answer_type: "number" },
      { question_text: "How many years have you lived in Northern Ireland?", answer_type: "number" },
      { question_text: "How many years have you lived in the United Kingdom?", answer_type: "number" },
    ],
    conditions: [
      { routing_index: 0, check_index: 0, goto_index: nil, answer_value: "No", skip_to_end: true },
      { routing_index: 1, check_index: 1, goto_index: 3, answer_value: "Scotland" },
      { routing_index: 1, check_index: 1, goto_index: 4, answer_value: "Wales" },
    ],
  )

  copy_of_answers_form = SeedFormsHelper.create_live_form!(
    user: craig,
    name: "Copy of answers form",
    **common_form_attrs,
    steps: [
      { question_text: "What is your full name?", answer_type: "name", answer_settings: { input_type: "full_name", title_needed: "false" } },
    ],
  )
  copy_of_answers_form.send_copy_of_answers = "enabled"

  GroupForm.create! group: end_to_end_group, form_id: all_question_types_form.id # All question types form
  GroupForm.create! group: end_to_end_group, form_id: e2e_s3_forms.id # s3 submission test form
  GroupForm.create! group: test_group, form_id: branch_route_form.id # Branch routing form
  GroupForm.create! group: test_group, form_id: none_of_the_above_form.id # None of the above form
  GroupForm.create! group: test_group, form_id: welsh_form.id # Welsh form
  GroupForm.create! group: multiple_branches_test_group, form_id: multiple_branch_form.id
  GroupForm.create! group: test_group, form_id: copy_of_answers_form.id
end
