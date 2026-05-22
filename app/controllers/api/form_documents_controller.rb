# frozen_string_literal: true

class Api::FormDocumentsController < ApplicationController
  def show
    render json: projected_content
  end

  def group
    render json: Form.find(form_document_params[:form_id]).group
  end

private

  def projected_content
    document = resolve_form_document
    raise ActiveRecord::RecordNotFound if document.blank?

    language = form_document_params[:language]
    unless TranslatableString::SUPPORTED_LOCALES.include?(language)
      raise ActiveRecord::RecordNotFound
    end

    FormDocument::LocaleProjection.project(document.content, language:)
  end

  def resolve_form_document
    form = Form.find(form_document_params[:form_id])
    tag = form_document_params[:tag]

    case tag
    when "draft"
      form.draft_form_document
    when "live"
      form.live_form_document
    when "archived"
      form.archived? ? form.live_form_document : nil
    end
  end

  def form_document_params
    permitted_params = params.permit(:form_id, :tag, :language)
    permitted_params[:language] ||= "en"
    permitted_params
  end
end
