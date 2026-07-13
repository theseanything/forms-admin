require "rails_helper"

RSpec.describe Organisation, type: :model do
  it "is an error to create an organisation with an existing slug" do
    organisation = create(:organisation, slug: "duplicate-org")

    expect {
      described_class.create!(govuk_content_id: Faker::Internet.uuid, slug: organisation.slug, name: organisation.name)
    }.to raise_error ActiveRecord::RecordNotUnique
  end

  describe "factory" do
    it "does not create organisation if already exists" do
      existing_organisation = create(:organisation, slug: "duplicate-org")
      new_organisation = nil

      expect {
        new_organisation = create(:organisation, slug: "duplicate-org")
      }.not_to raise_error

      expect(new_organisation).to eq(existing_organisation)
    end
  end

  describe "versioning", :versioning do
    it "enables paper trail" do
      expect(described_class.new).to be_versioned
    end
  end

  describe "scopes" do
    describe ".with_users" do
      it "returns organisations with distinct users" do
        FactoryBot.create(:organisation, slug: "org_3")
        organisation2 = FactoryBot.create(:organisation, slug: "org_2")
        organisation1 = FactoryBot.create(:organisation, slug: "org_1")

        FactoryBot.create(:user, organisation: organisation1)
        FactoryBot.create(:user, organisation: organisation1)
        FactoryBot.create(:user, organisation: organisation2)

        organisations_with_users = described_class.with_users

        expect(organisations_with_users).to eq([organisation1, organisation2])
      end
    end

    describe ".not_closed" do
      it "returns organisations which are not closed" do
        organisation = create :organisation
        create :organisation, slug: "closed-org", closed: true

        expect(described_class.not_closed).to eq [organisation]
      end
    end

    describe ".by_name" do
      let!(:justice_org) { create :organisation, slug: "ministry-of-justice" }
      let!(:transport_org) { create :organisation, slug: "department-for-transport" }

      it "matches a partial name, ignoring case" do
        expect(described_class.by_name("justice")).to contain_exactly(justice_org)
      end

      it "matches the abbreviation, ignoring case" do
        expect(described_class.by_name("dft")).to contain_exactly(transport_org)
      end

      it "returns all organisations when the name is blank" do
        expect(described_class.by_name(nil)).to contain_exactly(justice_org, transport_org)
        expect(described_class.by_name("")).to contain_exactly(justice_org, transport_org)
      end
    end

    describe ".by_agreement_type" do
      let!(:organisation_with_crown_mou) { create :organisation, :with_signed_mou, slug: "org-with-crown-mou" }
      let!(:organisation_with_non_crown_agreement) { create :organisation, slug: "org-with-non-crown-agreement" }
      let!(:organisation_without_agreement) { create :organisation, slug: "org-without-agreement" }

      before do
        create :mou_signature_for_organisation, organisation: organisation_with_non_crown_agreement, agreement_type: :non_crown
      end

      it "returns organisations with a Crown MOU when crown" do
        expect(described_class.by_agreement_type("crown")).to contain_exactly(organisation_with_crown_mou)
      end

      it "returns organisations with a non-crown agreement when non_crown" do
        expect(described_class.by_agreement_type("non_crown")).to contain_exactly(organisation_with_non_crown_agreement)
      end

      it "returns organisations with any signed agreement when signed" do
        expect(described_class.by_agreement_type("signed")).to contain_exactly(organisation_with_crown_mou, organisation_with_non_crown_agreement)
      end

      it "returns organisations without a signed agreement when none" do
        expect(described_class.by_agreement_type("none")).to contain_exactly(organisation_without_agreement)
      end

      it "returns all organisations when blank" do
        expect(described_class.by_agreement_type(nil)).to contain_exactly(organisation_with_crown_mou, organisation_with_non_crown_agreement, organisation_without_agreement)
      end

      it "returns all organisations for an unknown value" do
        expect(described_class.by_agreement_type("malicious")).to contain_exactly(organisation_with_crown_mou, organisation_with_non_crown_agreement, organisation_without_agreement)
      end
    end
  end

  describe "#name_with_abbreviation" do
    it "uses abbreviation when it is not the same as name" do
      organisation = build :organisation, name: "An Organisation", abbreviation: "ABBR"
      expect(organisation.name_with_abbreviation).to eq "An Organisation (ABBR)"
    end

    it "does not use abbreviation when it is not present" do
      organisation = build :organisation, name: "An Organisation", abbreviation: "   "
      expect(organisation.name_with_abbreviation).to eq organisation.name
    end

    it "does not use abbreviation when it is present but the same as name" do
      organisation = build :organisation, name: "An Organisation", abbreviation: "An Organisation"
      expect(organisation.name_with_abbreviation).to eq organisation.name
    end
  end
end
