class Forms::RoutesInput < BaseInput
  attr_accessor :form, :routes

  def self.too_many_selection_options?(page)
    page.answer_settings["selection_options"].length > 10
  end

  def initialize(attributes = {})
    @form = attributes.delete(:form)
    super
  end

  def submit
    # TODO: Add validations - this is here so we don't forget it but the model
    # can't be invalid yet
    return false if invalid?

    Routes::SyncService.new(form:, routes:).sync_conditions_from_routes

    form.save_draft!
    true
  end

  def assign_form_values
    self.routes = Routes::BuildService.new(form:).build_routes
    self
  end

  def routes_attributes=(attributes)
    page_ids = attributes.values.map { |attrs| attrs["page_id"] }.compact
    pages_by_id = form.pages.where(id: page_ids).index_by(&:id)

    route_build_service = Routes::BuildService.new(form:)

    @routes = attributes.values.map { |route_attrs|
      page = pages_by_id[route_attrs["page_id"].to_i]
      next unless page # Skip if page not found or doesn't belong to form

      Forms::RouteInput.new(
        route_attrs.symbolize_keys.merge(
          page:,
          goto_options: route_build_service.options_for_goto_page(page, route_attrs["goto"]),
        ),
      )
    }.compact
  end
end
