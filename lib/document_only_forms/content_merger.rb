# frozen_string_literal: true

module DocumentOnlyForms
  class ContentMerger
    FORM_TRANSLATABLE_KEYS = %w[
      name
      privacy_policy_url
      support_email
      support_phone
      support_url
      support_url_text
      declaration_text
      declaration_markdown
      what_happens_next_markdown
      payment_url
    ].freeze

    STEP_TRANSLATABLE_KEYS = %w[question_text hint_text page_heading guidance_markdown].freeze
    CONDITION_TRANSLATABLE_KEYS = %w[exit_page_heading exit_page_markdown].freeze

    def self.merge_documents(en_doc:, cy_doc: nil)
      new(en_doc:, cy_doc:).merge
    end

    def initialize(en_doc:, cy_doc: nil)
      @en_content = (en_doc&.content || {}).deep_stringify_keys
      @cy_content = (cy_doc&.content || {}).deep_stringify_keys
    end

    def merge
      result = @en_content.deep_dup
      result.delete("language")

      FORM_TRANSLATABLE_KEYS.each do |key|
        next unless result.key?(key) || @cy_content.key?(key)

        result[key] = merge_field(result[key], @cy_content[key])
      end

      result["available_languages"] ||= merged_available_languages
      result["steps"] = merge_steps(result["steps"], @cy_content["steps"])
      result
    end

    ATTRIBUTES_NOT_IN_FORM_DOCUMENT = %i[
      external_id question_section_completed declaration_section_completed
      share_preview_completed welsh_completed
    ].freeze

    def self.from_form_record(form)
      en_content = Mobility.with_locale(:en) { build_from_relational(form) }
      cy_content = if form.available_languages.include?("cy")
                     Mobility.with_locale(:cy) { build_from_relational(form) }
                   end
      new(en_doc: OpenStruct.new(content: en_content), cy_doc: cy_content ? OpenStruct.new(content: cy_content) : nil).merge
    end

    def self.build_from_relational(form)
      content = form.as_json(
        except: ATTRIBUTES_NOT_IN_FORM_DOCUMENT,
        methods: %i[start_page steps],
      )
      content["form_id"] = content.delete("id").to_s
      convert_relational_steps_to_inline(content)
      content
    end

    def self.convert_relational_steps_to_inline(content)
      content["steps"] = Array(content["steps"]).map do |step|
        step = step.deep_stringify_keys
        data = (step["data"] || {}).deep_stringify_keys
        STEP_TRANSLATABLE_KEYS.each do |key|
          step[key] = { "en" => data.delete(key) } if data[key].present?
        end
        step["answer_type"] ||= data.delete("answer_type")
        step["data"] = {
          "is_optional" => data["is_optional"],
          "is_repeatable" => data["is_repeatable"],
          "answer_settings" => data["answer_settings"],
        }.compact
        step["routing_conditions"] = Array(step["routing_conditions"]).map { |c| convert_condition(c) }
        step
      end
      FORM_TRANSLATABLE_KEYS.each do |key|
        content[key] = { "en" => content[key] } if content[key].is_a?(String)
      end
      content["available_languages"] = form_available_languages(content, form_available: content["available_languages"])
      content
    end

    def self.convert_condition(condition)
      condition = condition.deep_stringify_keys
      CONDITION_TRANSLATABLE_KEYS.each do |key|
        condition[key] = { "en" => condition[key] } if condition[key].is_a?(String)
      end
      condition
    end

    def self.convert_flat_document_to_inline(content)
      content = content.deep_stringify_keys
      content.delete("language")
      FORM_TRANSLATABLE_KEYS.each do |key|
        content[key] = { "en" => content[key] } if content[key].is_a?(String)
      end
      content["steps"] = Array(content["steps"]).map do |step|
        step = step.deep_stringify_keys
        data = (step["data"] || {}).deep_stringify_keys
        if data["question_text"].is_a?(String)
          STEP_TRANSLATABLE_KEYS.each do |key|
            step[key] = { "en" => data.delete(key) } if data[key].present?
          end
          step["answer_type"] ||= data.delete("answer_type")
          step["data"] = {
            "is_optional" => data["is_optional"],
            "is_repeatable" => data["is_repeatable"],
            "answer_settings" => data["answer_settings"],
          }.compact
        end
        step["routing_conditions"] = Array(step["routing_conditions"]).map { |c| convert_condition(c) }
        step
      end
      content
    end

  private

    def merge_field(en_val, cy_val)
      en_str = en_val.is_a?(Hash) ? en_val["en"] || en_val.values.first : en_val
      cy_str = cy_val.is_a?(Hash) ? cy_val["en"] || cy_val["cy"] || cy_val.values.first : cy_val
      TranslatableString.merge_locales(en_value: en_str, cy_value: cy_str)
    end

    def merged_available_languages
      langs = []
      langs << "en"
      langs << "cy" if @cy_content.present? && @cy_content.any?
      langs.uniq
    end

    def merge_steps(en_steps, cy_steps)
      cy_by_id = Array(cy_steps).index_by { |s| s["id"] }
      Array(en_steps).map do |en_step|
        cy_step = cy_by_id[en_step["id"]]
        merge_step(en_step, cy_step)
      end
    end

    def merge_step(en_step, cy_step)
      step = en_step.deep_dup
      cy_step ||= {}
      en_data = (step["data"] || {}).deep_stringify_keys
      cy_data = (cy_step["data"] || {}).deep_stringify_keys

      if step["question_text"].is_a?(String) || en_data["question_text"].is_a?(String)
        step = self.class.convert_flat_document_to_inline({ "steps" => [step] })["steps"].first
        cy_converted = cy_step.present? ? self.class.convert_flat_document_to_inline({ "steps" => [cy_step] })["steps"].first : {}
        cy_step = cy_converted
      end

      STEP_TRANSLATABLE_KEYS.each do |key|
        step[key] = merge_field(step[key], cy_step[key]) if step[key].present? || cy_step[key].present?
      end

      if en_data["answer_settings"].present? || cy_data["answer_settings"].present?
        step["data"] ||= {}
        step["data"]["answer_settings"] = merge_answer_settings(en_data["answer_settings"], cy_data["answer_settings"])
      end

      en_conditions = Array(step["routing_conditions"])
      cy_conditions = Array(cy_step["routing_conditions"])
      step["routing_conditions"] = merge_conditions(en_conditions, cy_conditions)
      step
    end

    def merge_answer_settings(en_settings, cy_settings)
      return en_settings if cy_settings.blank?

      en_settings = (en_settings || {}).deep_dup
      cy_settings = (cy_settings || {}).deep_dup
      if en_settings["selection_options"].is_a?(Array)
        cy_options = Array(cy_settings["selection_options"])
        en_settings["selection_options"] = en_settings["selection_options"].map.with_index do |opt, i|
          opt = opt.deep_dup
          cy_opt = cy_options[i]
          opt["name"] = merge_field(opt["name"], cy_opt&.dig("name")) if opt["name"].is_a?(String) || cy_opt
          opt
        end
      end
      en_settings
    end

    def merge_conditions(en_conditions, cy_conditions)
      cy_by_id = cy_conditions.index_by { |c| c["id"] }
      en_conditions.map do |en_c|
        cy_c = cy_by_id[en_c["id"]] || {}
        merged = en_c.deep_dup
        if merged["exit_page_heading"].is_a?(String)
          merged = self.class.convert_condition(merged)
          cy_c = self.class.convert_condition(cy_c) if cy_c["exit_page_heading"].is_a?(String)
        end
        CONDITION_TRANSLATABLE_KEYS.each do |key|
          merged[key] = merge_field(merged[key], cy_c[key]) if merged[key].present? || cy_c[key].present?
        end
        merged
      end
    end

    class << self
      def form_available_languages(content, form_available:)
        available = form_available || %w[en]
        available = available.is_a?(Array) ? available : [available]
        available.map(&:to_s)
      end
    end
  end
end
