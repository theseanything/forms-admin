class CreateFormService
  class CreateFormEvent < ApplicationRecord
    belongs_to :user
    belongs_to :group
  end

  def create!(creator:, group:, name:)
    event = begin
      CreateFormEvent.create!(group:, form_name: name, user: creator, dedup_version: 1)
    rescue ActiveRecord::RecordNotUnique
      previous_event = CreateFormEvent.order(created_at: :desc).find_by(group:, form_name: name)

      if previous_event.user == creator && previous_event.created_at > 1.second.ago
        timeout_message = "CreateFormService#create! timed out waiting for form to be created by previous invocation: " \
          "did something go wrong with creating form '#{name}' in group #{group.id} by user #{creator.id}?"

        Timeout.timeout(1, nil, timeout_message) do
          while previous_event.form_id.blank?
            sleep(0.01)
            previous_event.reload
          end
        end

        previous_event
      else
        CreateFormEvent.create!(group:, form_name: name, user: creator, dedup_version: previous_event.dedup_version + 1)
      end
    end

    if event.form_id.present?
      form = Form.find(event.form_id)
    else
      form = Form.create!(creator_id: creator.id)
      form.draft_content_service.update_content_attributes!(
        "name" => { "en" => name },
        "form_slug" => name.parameterize,
      )
      GroupForm.create!(group:, form_id: form.id)
      event.update!(form_id: form.id)
    end

    form
  end
end
