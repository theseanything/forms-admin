# frozen_string_literal: true

class FormCondition
  include ConditionMethods

  attr_accessor :id, :answer_value, :goto_page_id, :check_page_id, :routing_page_id,
                :skip_to_end, :exit_page_heading, :exit_page_markdown
  attr_reader :form, :draft_service

  def self.create_and_update_form!(form_id:, routing_page_id:, **attrs)
    form = Form.find(form_id)
    draft_service = form.draft_content_service
    hash = draft_service.content_hash
    step_data = hash["steps"]&.find { |s| s["id"].to_s == routing_page_id.to_s }
    raise ActiveRecord::RecordNotFound unless step_data

    condition = {
      "id" => next_condition_id(draft_service),
      "routing_page_id" => routing_page_id.to_s,
      "check_page_id" => attrs[:check_page_id].to_s,
      "answer_value" => attrs[:answer_value],
      "goto_page_id" => attrs[:goto_page_id]&.to_s,
      "skip_to_end" => attrs[:skip_to_end] || false,
      "exit_page_heading" => TranslatableString.normalize(attrs[:exit_page_heading]),
      "exit_page_markdown" => TranslatableString.normalize(attrs[:exit_page_markdown]),
    }.compact

    step_data["routing_conditions"] ||= []
    step_data["routing_conditions"] << condition
    draft_service.save_content!(hash)
    new(form:, condition:, step_id: routing_page_id)
  end

  def self.next_condition_id(draft_service)
    ids = draft_service.conditions.map { |c| c.id.to_i }
    (ids.max || 0) + 1
  end

  def initialize(form:, condition:, step_id:)
    @form = form
    @draft_service = form.draft_content_service
    @step_id = step_id.to_s
    @condition = condition.stringify_keys
    assign_from_hash
  end

  def save_and_update_form
    update_in_document
    draft_service.save_question_changes!
    true
  end

  def destroy_and_update_form!
    hash = draft_service.content_hash
    step_data = hash["steps"]&.find { |s| s["id"].to_s == @step_id.to_s }
    return false unless step_data

    step_data["routing_conditions"] = Array(step_data["routing_conditions"]).reject { |c| c["id"].to_s == id.to_s }
    draft_service.save_content!(hash)
    draft_service.save_question_changes!
    true
  end

  def validation_errors
    condition_model.validation_errors
  end

  def errors_with_fields
    condition_model.errors_with_fields
  end

  def as_json(options = {})
    condition_model.as_json(options)
  end

  def as_form_document_condition
    {
      "id" => id.to_s,
      "answer_value" => answer_value,
      "goto_page_id" => goto_page_id&.to_s,
      "check_page_id" => check_page_id.to_s,
      "routing_page_id" => routing_page_id.to_s,
      "skip_to_end" => skip_to_end,
      "exit_page_heading" => @exit_page_heading,
      "exit_page_markdown" => @exit_page_markdown,
    }.compact
  end

  def exit_page_heading=(value)
    @exit_page_heading = value
  end

  def exit_page_heading(locale: :en)
    TranslatableString.for_locale(@exit_page_heading, locale:)
  end

  def exit_page_markdown=(value)
    @exit_page_markdown = value
  end

  def exit_page_markdown(locale: :en)
    TranslatableString.for_locale(@exit_page_markdown, locale:)
  end

  def exit_page?
    is_exit_page?
  end

  def skip_to_end?
    skip_to_end == true
  end

  def secondary_skip?
    answer_value.blank? && check_page_id != routing_page_id
  end

  def routing_page
    form.pages.find { |page| page.id.to_s == routing_page_id.to_s }
  end

  def exit_page_heading_cy
    exit_page_heading(locale: :cy)
  end

  def exit_page_heading_cy=(value)
    @exit_page_heading = TranslatableString.set_for_locale(@exit_page_heading, locale: :cy, string: value)
  end

  def exit_page_markdown_cy
    exit_page_markdown(locale: :cy)
  end

  def exit_page_markdown_cy=(value)
    @exit_page_markdown = TranslatableString.set_for_locale(@exit_page_markdown, locale: :cy, string: value)
  end

  def save!
    save_and_update_form
  end

  def reload
    @form = Form.find(@form.id)
    @draft_service = @form.draft_content_service
    hash = @draft_service.content_hash
    step_data = hash["steps"]&.find { |s| s["id"].to_s == @step_id.to_s }
    condition_data = Array(step_data&.dig("routing_conditions")).find { |c| c["id"].to_s == id.to_s }
    if condition_data
      @condition = condition_data.stringify_keys
      assign_from_hash
    end
    self
  end

  def update!(attrs = {})
    attrs.each { |key, value| public_send("#{key}=", value) if respond_to?("#{key}=") }
    save!
  end

  def self.exists?(condition_id)
    Form.find_each.any? do |form|
      next if form.draft_form_document.blank?

      form.draft_content_service.conditions.any? { |condition| condition.id.to_s == condition_id.to_s }
    end
  end

private

  def assign_from_hash
    @id = @condition["id"]
    @answer_value = @condition["answer_value"]
    @goto_page_id = @condition["goto_page_id"]
    @check_page_id = @condition["check_page_id"]
    @routing_page_id = @condition["routing_page_id"]
    @skip_to_end = @condition["skip_to_end"]
    @exit_page_heading = @condition["exit_page_heading"]
    @exit_page_markdown = @condition["exit_page_markdown"]
  end

  def update_in_document
    hash = draft_service.content_hash
    step_data = hash["steps"]&.find { |s| s["id"].to_s == @step_id.to_s }
    return unless step_data

    conditions = step_data["routing_conditions"] || []
    index = conditions.index { |c| c["id"].to_s == id.to_s }
    return unless index

    conditions[index] = {
      "id" => id,
      "routing_page_id" => routing_page_id.to_s,
      "check_page_id" => check_page_id.to_s,
      "routing_page_id" => routing_page_id.to_s,
      "answer_value" => answer_value,
      "goto_page_id" => goto_page_id&.to_s,
      "skip_to_end" => skip_to_end,
      "exit_page_heading" => TranslatableString.normalize(@exit_page_heading),
      "exit_page_markdown" => TranslatableString.normalize(@exit_page_markdown),
    }.compact
    step_data["routing_conditions"] = conditions
    draft_service.save_content!(hash)
  end

  def condition_model
    steps = draft_service.content_hash["steps"]
    model = FormDocument::Condition.new(
      id:,
      answer_value:,
      goto_page_id:,
      check_page_id:,
      routing_page_id:,
      skip_to_end:,
      exit_page_heading:,
      exit_page_markdown:,
    )
    model.all_steps = steps
    model
  end
end

Condition = FormCondition unless defined?(Condition)
