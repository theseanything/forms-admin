class NormaliseConditionsService
  attr_reader :form

  def initialize(form:)
    @form = form
  end

  def normalise_conditions
    conditions = form.conditions

    return false if conditions.any? { unfixable_validation_errors?(it) }

    conditions
      .filter { routes_to_next_page?(it) }
      .each(&:destroy)

    form.reload

    conditions
  end

private

  def routes_to_next_page?(condition)
    !condition.warning_routing_to_next_page.nil?
  end

  def unfixable_validation_errors?(condition)
    condition.validation_errors.any? do |validation_error|
      validation_error.name != "cannot_route_to_next_page"
    end
  end
end
