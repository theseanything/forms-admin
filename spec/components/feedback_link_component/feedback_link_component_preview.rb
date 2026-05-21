class FeedbackLinkComponent::FeedbackLinkComponentPreview < ViewComponent::Preview
  def default
    render(FeedbackLinkComponent::View.new)
  end

  def with_feedback_url
    render(FeedbackLinkComponent::View.new(feedback_url: "/feedback"))
  end
end
