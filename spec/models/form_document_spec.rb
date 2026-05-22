require "rails_helper"

RSpec.describe FormDocument, type: :model do
  it "is valid with valid attributes" do
    form_document = build(:form_document)
    expect(form_document).to be_valid
  end

  it "is invalid without a form" do
    form_document = build(:form_document, form: nil)
    expect(form_document).not_to be_valid
  end

  it "has a default created_at and updated_at" do
    travel_to Time.zone.local(2023, 10, 1, 10, 0, 0) do
      form_document = create(:form_document)

      expect(form_document.created_at).to eq(Time.zone.now)
      expect(form_document.updated_at).to eq(Time.zone.now)
    end
  end

  it "belongs to a Form" do
    form_document = build(:form_document)

    expect(form_document.form).to be_a(Form)
  end

  it "is readonly when pointed to as live document" do
    form = create(:form, :live)
    expect(form.live_form_document.readonly?).to be true
  end

  it "allows updating draft document" do
    form = create(:form)
    expect(form.draft_form_document.readonly?).to be false
  end
end
