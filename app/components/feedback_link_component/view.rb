# frozen_string_literal: true

module FeedbackLinkComponent
  class View < ApplicationComponent
    def initialize(feedback_url: nil)
      super()
      @feedback_url = feedback_url
    end

    def render?
      @feedback_url.present?
    end
  end
end
