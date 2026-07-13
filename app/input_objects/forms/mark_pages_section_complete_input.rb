class Forms::MarkPagesSectionCompleteInput < Forms::MarkCompleteInput
  validate :has_routing_errors, if: :marked_complete?

  def submit
    return false if invalid?

    form.question_section_completed = mark_complete
    form.save_draft!
  end

  def assign_form_values
    self.mark_complete = form.try(:question_section_completed)
    self
  end

  def has_routing_errors
    if FeatureService.new(group: form.group).enabled?(:multiple_branches)
      NormaliseConditionsService.new(form:).normalise_conditions
    end

    errors.add :base, :has_routing_errors if form.has_routing_errors?
  end
end
