# frozen_string_literal: true

class Routes::SyncService
  attr_reader :form, :routes

  def initialize(form:, routes:)
    @form = form
    @routes = routes
  end

  def sync_conditions_from_routes
    ActiveRecord::Base.transaction do
      update_or_create_conditions
      destroy_stale_conditions
      form.draft_content_service.save_question_changes!
    end
  end

private

  def content_hash
    @content_hash ||= form.draft_content_service.content_hash.deep_dup
  end

  def update_or_create_conditions
    routes.each do |route|
      next if route.goes_to_default_next_page?

      step = content_hash["steps"]&.find { |s| s["id"].to_s == route.page_id.to_s }
      next unless step

      conditions = step["routing_conditions"] || []
      existing_index = conditions.index do |c|
        c["routing_page_id"].to_s == route.page.id.to_s && c["answer_value"].presence == route.answer_value.presence
      end

      attrs = route.condition_attributes.stringify_keys
      attrs["routing_page_id"] = route.page.id.to_s
      attrs["check_page_id"] = route.page.id.to_s unless attrs.key?("check_page_id")
      attrs["goto_page_id"] = attrs["goto_page_id"].to_s if attrs["goto_page_id"].present?

      if existing_index
        conditions[existing_index] = conditions[existing_index].merge(attrs)
      else
        attrs["id"] = next_condition_id(conditions)
        conditions << attrs
      end

      step["routing_conditions"] = conditions
    end

    form.draft_content_service.save_content!(content_hash)
  end

  def destroy_stale_conditions
    default_routes = routes.select(&:goes_to_default_next_page?)
    return if default_routes.none?

    content_hash["steps"]&.each do |step|
      step["routing_conditions"] = Array(step["routing_conditions"]).reject do |condition|
        default_routes.any? do |route|
          condition["routing_page_id"].to_s == route.page.id.to_s &&
            condition["answer_value"].presence == route.answer_value.presence
        end
      end
    end

    form.draft_content_service.save_content!(content_hash)
  end

  def next_condition_id(conditions)
    ids = conditions.map { |c| c["id"].to_i }
    (ids.max || 0) + 1
  end
end
