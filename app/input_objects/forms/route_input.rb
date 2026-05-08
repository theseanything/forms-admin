class Forms::RouteInput < BaseInput
  include ActiveModel::Attributes

  END_OF_FORM_VALUE = "end_of_form".freeze
  DEFAULT_VALUE = "default".freeze

  attribute :id # id of the Condition
  attribute :page_id, :integer
  attribute :goto
  attribute :answer_value

  attr_accessor :page, :goto_options, :label

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
end
