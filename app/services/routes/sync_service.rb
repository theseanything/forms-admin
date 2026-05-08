## Take a form and an array of RouteInput objects and update the form's
# conditions to match the routes.
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
    end
  end

private

  def update_or_create_conditions
    routes.each do |route|
      # Conditions are only needed for non-default routing.
      next if route.goes_to_default_next_page?

      condition = Condition.find_or_initialize_by(
        routing_page_id: route.page_id,
        answer_value: route.answer_value.presence,
      )

      condition.assign_attributes(
        route.condition_attributes,
      )
      condition.save!
    end
  end

  def destroy_stale_conditions
    default_routes = routes.select(&:goes_to_default_next_page?)

    # If there are no routes marked as default, there's nothing to destroy.
    return if default_routes.none?

    stale_conditions = form.conditions.where(
      routing_page_id: default_routes.map(&:page_id),
      answer_value: default_routes.map { |r| r.answer_value.presence },
    )
    stale_conditions.destroy_all
  end
end
