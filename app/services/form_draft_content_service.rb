# frozen_string_literal: true

class FormDraftContentService
  attr_reader :form

  def initialize(form)
    @form = form
    @operations = FormDocumentOperationsService.new(form)
  end

  def content_hash
    @content_hash ||= load_content_hash
  end

  def content
    @content ||= FormDocument::Content.new(content_hash)
  end

  def steps
    ordered_steps
  end

  def find_step(step_id)
    step_data = content_hash["steps"]&.find { |s| s["id"].to_s == step_id.to_s }
    FormStep.new(form:, step_data:, draft_service: self) if step_data
  end

  def steps_for_list
    ordered_steps.map { |s| FormStep.new(form:, step_data: s, draft_service: self) }
  end

  def conditions
    steps.flat_map do |step|
      Array(step["routing_conditions"]).map do |c|
        FormDocument::Condition.new(**c.stringify_keys)
      end
    end
  end

  def add_step!(attrs)
    steps = ordered_steps
    position = attrs[:position] || steps.length + 1
    step_id = attrs[:id] || ExternalIdProvider.generate_unique_id_for(FormStepId)
    new_step = build_step_hash(attrs.merge(id: step_id, position:))
    steps << new_step
    reassign_positions_and_next_steps!(steps)
    save_question_changes!
    find_step(step_id)
  end

  def update_step!(step_id, attrs)
    steps = ordered_steps
    index = steps.index { |s| s["id"] == step_id }
    raise ActiveRecord::RecordNotFound unless index

    steps[index] = build_step_hash(steps[index].merge(attrs.stringify_keys))
    reassign_positions_and_next_steps!(steps)
    save_question_changes!
    find_step(step_id)
  end

  def destroy_step!(step_id)
    steps = ordered_steps.reject { |s| s["id"] == step_id }
    reassign_positions_and_next_steps!(steps)
    save_question_changes!
  end

  def move_step!(step_id, direction)
    steps = ordered_steps
    index = steps.index { |s| s["id"] == step_id }
    return false unless index

    new_index = direction == :up ? index - 1 : index + 1
    return false if new_index.negative? || new_index >= steps.length

    steps[index], steps[new_index] = steps[new_index], steps[index]
    reassign_positions_and_next_steps!(steps)
    save_question_changes!
    true
  end

  def update_content_attributes!(attrs)
    hash = content_hash.merge(attrs.stringify_keys)
    save_content!(hash)
  end

  def save_question_changes!
    form.question_section_completed = false
    form.touch unless form.changed?
    @operations.save_draft!
    @content_hash = nil
    @content = nil
  end

  def save_content!(hash)
    normalise_welsh_in_content!(hash)
    @operations.save_draft_content!(hash)
    @content_hash = nil
    @content = nil
  end

  def normalise_welsh!
    return unless content_hash["available_languages"]&.include?("cy")

    hash = content_hash.deep_dup
    normalise_welsh_in_content!(hash)
    save_content!(hash)
  end

  def qualifying_route_steps
    max_routes = 2
    steps_list = steps_for_list
    condition_counts = conditions.group_by(&:check_page_id).transform_values(&:length)

    steps_list.filter do |step|
      step.answer_type == "selection" &&
        step.only_one_option? &&
        step.position != steps_list.length &&
        condition_counts.fetch(step.id, 0) < max_routes &&
        step.routing_conditions.none?(&:secondary_skip?)
    end
  end

  def page_number(step)
    return steps.length + 1 if step.nil?

    index = ordered_steps.index { |s| s["id"] == step.id }
    (index.nil? ? steps.length : index) + 1
  end

  def next_step_after(current_step)
    steps_list = steps_for_list
    pair = steps_list.each_cons(2).find { |s, _| s.id == current_step.id }
    pair&.last
  end

private

  def load_content_hash
    if form.draft_form_document.present?
      form.draft_form_document.content.deep_dup
    elsif form.live_form_document.present?
      form.live_form_document.content.deep_dup
    else
      default_content_hash
    end
  end

  def default_content_hash
    {
      "form_id" => form.id.to_s,
      "name" => { "en" => "" },
      "available_languages" => %w[en],
      "form_slug" => "",
      "submission_type" => "email",
      "submission_format" => [],
      "send_copy_of_answers" => "disabled",
      "steps" => [],
    }
  end

  def ordered_steps
    Array(content_hash["steps"]).sort_by { |s| s["position"].to_i }
  end

  def build_step_hash(attrs)
    attrs = attrs.stringify_keys
    {
      "id" => attrs["id"],
      "type" => attrs["type"] || "question",
      "position" => attrs["position"],
      "next_step_id" => attrs["next_step_id"],
      "question_text" => TranslatableString.normalize(attrs["question_text"]),
      "hint_text" => TranslatableString.normalize(attrs["hint_text"]),
      "page_heading" => TranslatableString.normalize(attrs["page_heading"]),
      "guidance_markdown" => TranslatableString.normalize(attrs["guidance_markdown"]),
      "answer_type" => attrs["answer_type"],
      "data" => {
        "is_optional" => attrs.dig("data", "is_optional") || attrs["is_optional"],
        "is_repeatable" => attrs.dig("data", "is_repeatable") || attrs["is_repeatable"],
        "answer_settings" => attrs.dig("data", "answer_settings") || attrs["answer_settings"],
        "answer_settings_cy" => attrs.dig("data", "answer_settings_cy"),
      }.compact,
      "routing_conditions" => attrs["routing_conditions"] || [],
    }.compact
  end

  def reassign_positions_and_next_steps!(steps)
    steps.each_with_index do |step, index|
      step["position"] = index + 1
      step["next_step_id"] = steps[index + 1]&.dig("id")
    end
    content_hash["steps"] = steps
    content_hash["start_page"] = steps.first&.dig("id")
    save_content!(content_hash)
  end

  def normalise_welsh_in_content!(hash)
    %w[declaration_markdown payment_url support_email support_phone support_url support_url_text what_happens_next_markdown].each do |key|
      next unless hash[key].is_a?(Hash)

      hash[key]["cy"] = nil if hash[key]["en"].blank?
    end
    Array(hash["steps"]).each do |step|
      %w[question_text hint_text page_heading guidance_markdown].each do |key|
        next unless step[key].is_a?(Hash)

        step[key]["cy"] = nil if step[key]["en"].blank?
      end
      if step["page_heading"].is_a?(Hash) && step["page_heading"]["en"].blank? && step["guidance_markdown"].is_a?(Hash) && step["guidance_markdown"]["en"].blank?
        step["page_heading"]["cy"] = nil
        step["guidance_markdown"]["cy"] = nil
      end
    end
  end
end
