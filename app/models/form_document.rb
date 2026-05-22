# frozen_string_literal: true

class FormDocument < ApplicationRecord
  belongs_to :form
  belongs_to :supersedes, class_name: "FormDocument", optional: true

  before_save :prevent_mutation_of_live_document

  def readonly?
    id.present? && form.live_form_document_id == id
  end

  def content_object
    FormDocument::Content.new(content)
  end

  def readonly!
    raise ActiveRecord::ReadOnlyRecord, "Live form documents are immutable" if readonly?
  end

private

  def prevent_mutation_of_live_document
    return unless persisted? && readonly? && changed?

    raise ActiveRecord::ReadOnlyRecord, "Live form documents are immutable"
  end
end
