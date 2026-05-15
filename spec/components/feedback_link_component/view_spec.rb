require "rails_helper"

RSpec.describe FeedbackLinkComponent::View, type: :component do
  let(:feedback_url) { "/feedback" }

  before do
    render_inline(described_class.new(feedback_url:))
  end

  context "when feedback url is nil" do
    let(:feedback_url) { nil }

    it "does not render the component" do
      expect(page).not_to have_selector("*")
    end
  end

  context "when the feedback url is set" do
    let(:feedback_url) { "/feedback" }

    it "renders the heading" do
      expect(page).to have_css("h2", text: "Help us improve this service")
    end

    it "renders the body text" do
      expect(page).to have_text("Tell us about your experience using this service.")
      expect(page).to have_text("You’ll help us make improvements by giving us your feedback.")
    end

    it "includes a link to the feedback URL" do
      expect(page).to have_link("giving us your feedback", href: feedback_url)
    end
  end
end
