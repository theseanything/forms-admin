class Forms::RouteInput < BaseInput
  include ActiveModel::Attributes

  END_OF_FORM_VALUE = "end_of_form".freeze
  DEFAULT_VALUE = "default".freeze

  attribute :id # id of the Condition
  attribute :page_id, :integer
  attribute :goto
  attribute :answer_value

  attr_accessor :page, :goto_page, :goto_options, :label

  validate :route_is_not_backwards

  def goes_to_default_next_page?
    goto == DEFAULT_VALUE
  end

  def goes_to_end_of_form?
    goto == END_OF_FORM_VALUE
  end

  def condition_attributes
    if goes_to_end_of_form?
      { goto_page_id: nil, skip_to_end: true, check_page_id: page.id }
    elsif goes_to_default_next_page?
      nil
    else
      { goto_page_id: goto, skip_to_end: false, check_page_id: page.id }
    end
  end

private

  def route_is_not_backwards
    return if skippable_for_backwards_validation?

    return if goto_page.position > page.position

    errors.add(:goto, error_message_for_backwards_route)
  end

  def skippable_for_backwards_validation?
    goes_to_default_next_page? || goes_to_end_of_form? || goto_page.nil?
  end

  def error_message_for_backwards_route
    if Forms::RoutesInput.route_with_selection_options?(page)
      option_index = page.answer_settings.selection_options.find_index { |option| option["value"] == answer_value }
      I18n.t("errors.routes.cannot_route_backwards_from_selection_page", question_number: page.position, option_number: option_index + 1)
    else
      I18n.t("errors.routes.cannot_route_backwards_from_generic_page", question_number: page.position)
    end
  end
end
