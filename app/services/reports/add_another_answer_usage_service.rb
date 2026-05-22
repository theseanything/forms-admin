class Reports::AddAnotherAnswerUsageService
  def add_another_answer_forms
    forms = Form.includes(:draft_form_document, :live_form_document)
                .select { |form| repeatable_steps(form).any? }
                .map { |form| form_data(form) }

    OpenStruct.new(forms:, count: forms.length)
  end

private

  def repeatable_steps(form)
    content = report_document_content(form)
    return [] if content.blank?

    Array(content["steps"]).select { |step| step.dig("data", "is_repeatable") }
  end

  def report_document_content(form)
    if form.draft_form_document_id.present?
      form.draft_form_document&.content
    else
      form.live_form_document&.content
    end
  end

  def form_data(form)
    repeatable = repeatable_steps(form).map do |step|
      OpenStruct.new(
        page_id: step["id"],
        question_text: TranslatableString.for_locale(step["question_text"], locale: :en),
      )
    end

    OpenStruct.new(
      form_id: form.id,
      name: form.name,
      state: form.lifecycle_status.to_s,
      repeatable_pages: repeatable,
    )
  end
end
