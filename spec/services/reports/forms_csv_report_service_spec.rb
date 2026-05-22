require "rails_helper"

RSpec.describe Reports::FormsCsvReportService do
  subject(:csv_reports_service) do
    described_class.new(form_documents)
  end

  let(:organisation_name) { Faker::Company.name }
  let(:organisation_id) { Faker::Number.number }
  let(:group_name) { Faker::Lorem.sentence }
  let(:group_external_id) { Faker::Alphanumeric.alphanumeric(number: 8) }
  let(:form_documents) do
    forms.map do |form|
      FormDocumentFactoryHelpers.report_form_document_json(form).merge(
        "organisation_name" => organisation_name,
        "organisation_id" => organisation_id,
        "group_name" => group_name,
        "group_external_id" => group_external_id,
      )
    end
  end
  let(:form) do
    f = create(:form, :ready_for_live, :with_support, pages_count: 0, submission_type: "email", submission_format: %w[csv json],
                                                       payment_url: "https://www.gov.uk/payments/organisation/service", send_daily_submission_batch: true,
                                                       send_weekly_submission_batch: true)
    create(:page, :with_address_settings, form: f, is_repeatable: true)
    create(:page, :with_date_settings, form: f)
    create(:page, form: f, answer_type: "email")
    create(:page, :with_full_name_settings, form: f)
    create(:page, form: f, answer_type: "national_insurance_number")
    create(:page, form: f, answer_type: "number")
    create(:page, form: f, answer_type: "phone_number")
    create(:page, :with_selection_settings, form: f, is_optional: true)
    create(:page, :with_single_line_text_settings, form: f, is_repeatable: true)
    FormDocumentFactoryHelpers.publish_form!(f)
    f.reload
  end
  let(:forms) { [form, create(:form, :live)] }

  describe "#csv" do
    it "returns a CSV with a header row and a row for each form" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows.length).to eq 3
    end

    it "has expected values" do
      csv = csv_reports_service.csv
      rows = CSV.parse(csv)
      expect(rows[1]).to contain_exactly(
        form.id.to_s,
        "live",
        form.name,
        form.form_slug,
        organisation_name,
        organisation_id.to_s,
        group_name,
        group_external_id,
        form_documents.first["content"]["created_at"],
        form_documents.first["content"]["live_at"],
        form_documents.first["content"]["live_at"],
        "9",
        "false",
        "false",
        "false",
        "true",
        form.payment_url,
        form.support_url,
        form.support_url_text,
        form.support_email,
        form.support_phone,
        form.privacy_policy_url,
        form.what_happens_next_markdown,
        "email",
        "csv json",
        "true",
        "true",
      )
    end
  end
end
