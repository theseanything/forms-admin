# frozen_string_literal: true

class Pages::ChangeOrderService
  class FormPagesAddedError < StandardError; end

  def self.generate_new_page_order(page_ids_and_positions)
    pages_with_position = page_ids_and_positions.select { |page| page[:new_position].present? }
                                             .sort_by { |page| page[:new_position].to_i }
    pages_without_position = page_ids_and_positions.select { |page| page[:new_position].blank? }

    new_page_order = []
    (1..page_ids_and_positions.length).each do |position|
      next_page_index = pages_with_position.index { |page| page[:new_position].to_i <= position }
      next_page = pages_with_position.delete_at(next_page_index) if next_page_index
      next_page ||= pages_without_position.shift
      next_page ||= pages_with_position.shift
      new_page_order << next_page[:page_id]
    end

    new_page_order
  end

  def self.update_page_order(form:, page_ids_and_positions:)
    new_page_order = generate_new_page_order(page_ids_and_positions)
    draft_service = form.draft_content_service
    step_ids = draft_service.steps.map { |s| s["id"] }

    raise FormPagesAddedError if (step_ids.map(&:to_s) - new_page_order.map(&:to_s)).any?

    ordered_steps = new_page_order.filter_map do |step_id|
      draft_service.steps.find { |s| s["id"].to_s == step_id.to_s }
    end

    hash = draft_service.content_hash
    hash["steps"] = ordered_steps
    hash["start_page"] = ordered_steps.first&.dig("id")
    ordered_steps.each_with_index do |step, index|
      step["position"] = index + 1
      step["next_step_id"] = ordered_steps[index + 1]&.dig("id")
    end
    draft_service.save_content!(hash)
    draft_service.save_question_changes!
  end
end
