# frozen_string_literal: true

class FormDocument::Condition
  include ActiveModel::API
  include ActiveModel::Attributes

  include ConditionMethods

  attribute :id, :integer
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
  attribute :skip_to_end, :boolean
  attribute :answer_value, :string
  attribute :goto_page_id, :string
  attribute :check_page_id, :string
  attribute :routing_page_id, :string
  attribute :exit_page_heading, TranslatableStringType.new
  attribute :validation_errors, DataStructType.new
  attribute :exit_page_markdown, TranslatableStringType.new

  attr_accessor :all_steps

  def initialize(attributes = {})
    attributes = attributes.stringify_keys
    attributes.slice!(*self.class.attribute_names)
    super
  end

  def validation_errors
    [
      warning_goto_page_doesnt_exist,
      warning_answer_doesnt_exist,
      warning_routing_to_next_page,
      warning_goto_page_before_routing_page,
    ].compact
  end

  def warning_goto_page_doesnt_exist
    return nil if is_exit_page?
    return nil if is_end_of_form?

    return nil if step_exists?(goto_page_id)

    DataStruct.new(name: "goto_page_doesnt_exist")
  end

  def warning_answer_doesnt_exist
    return nil if has_precondition? && answer_value.nil?

    check_step = find_step(check_page_id)
    answer_options = check_step&.dig("data", "answer_settings", "selection_options")&.map { |o| o["name"] }
    return nil if answer_options.blank? || answer_options.include?(answer_value)

    DataStruct.new(name: "answer_value_doesnt_exist")
  end

  def warning_routing_to_next_page
    routing_step = find_step(routing_page_id)
    return nil if routing_step.nil?

    goto_step = find_step(goto_page_id)
    routing_position = routing_step["position"].to_i
    goto_position = is_end_of_form? ? steps.length + 1 : goto_step&.dig("position").to_i

    return DataStruct.new(name: "cannot_route_to_next_page") if goto_position == routing_position + 1

    nil
  end

  def warning_goto_page_before_routing_page
    routing_step = find_step(routing_page_id)
    goto_step = find_step(goto_page_id)
    return nil if goto_step.blank? || routing_step.blank?

    if goto_step["position"].to_i <= routing_step["position"].to_i
      DataStruct.new(name: "cannot_have_goto_page_before_routing_page")
    end
  end

  def is_end_of_form?
    goto_page_id.nil? && skip_to_end
  end

  def has_routing_errors
    validation_errors.any?
  end

  alias_method :has_routing_errors?, :has_routing_errors

  def errors_with_fields
    error_fields = {
      answer_value_doesnt_exist: :answer_value,
      goto_page_doesnt_exist: :goto_page_id,
      cannot_have_goto_page_before_routing_page: :goto_page_id,
      cannot_route_to_next_page: :goto_page_id,
    }
    validation_errors.map do |error|
      { name: error[:name], field: error_fields[error[:name].to_sym] || :answer_value }
    end
  end

  def as_json(options = {})
    super(options.reverse_merge(methods: %i[validation_errors has_routing_errors]))
  end

  def to_content_hash
    attributes.stringify_keys.slice(*self.class.attribute_names).tap do |h|
      h["exit_page_heading"] = TranslatableString.normalize(exit_page_heading)
      h["exit_page_markdown"] = TranslatableString.normalize(exit_page_markdown)
    end
  end

private

  def steps
    @all_steps || []
  end

  def find_step(step_id)
    steps.find { |s| s["id"] == step_id }
  end

  def step_exists?(step_id)
    step_id.present? && steps.any? { |s| s["id"] == step_id }
  end

  def has_precondition?
    check_page_id.present? && check_page_id != routing_page_id
  end
end
