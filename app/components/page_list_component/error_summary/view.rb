module PageListComponent
  module ErrorSummary
    class View < ApplicationComponent
      def initialize(form)
        super()
        @form = form
      end

      def self.error_id(number)
        "condition_#{number}"
      end

      def self.page_error_id(page)
        "page-#{page.id}"
      end

      def self.generate_error_message(error_name, condition:, page:)
        # TODO: route_number is hardcoded as 1 here because we know there can be only two conditions. It will need to change in future
        # https://trello.com/c/BfkZEIgM/3446-set-route-count-dynamically-instead-of-hard-coding-it
        route_number = condition.secondary_skip? ? I18n.t("errors.page_conditions.route_number_for_any_other_answer") : 1

        interpolation_variables = { question_number: page.position, route_number: }

        scope = "errors.page_conditions"
        defaults = [:"#{error_name}"]
        defaults.prepend(:"any_other_answer_route.#{error_name}") if condition.secondary_skip?

        I18n.t(defaults.first, default: defaults.drop(1), scope:, **interpolation_variables)
      end

      def self.multiple_branch_error_message(page)
        page_errors = page.routing_conditions.filter(&:warning_goto_page_before_routing_page)

        return if page_errors.blank?

        if Forms::RoutesInput.route_with_selection_options?(page)
          I18n.t("errors.routes.page_list.cannot_route_backwards_from_selection_page", question_number: page.position, count: page_errors.count)
        else
          I18n.t("errors.routes.page_list.cannot_route_backwards_from_generic_page", question_number: page.position)
        end
      end

      def error_object(error_name:, condition:, page:)
        OpenStruct.new(
          message: self.class.generate_error_message(error_name, condition:, page:),
          link: "##{self.class.error_id(condition.id)}",
        )
      end

      def errors_for_summary
        if FeatureService.new(group: @form.group).enabled?(:multiple_branches)
          @form.pages.map { |page|
            error_message = self.class.multiple_branch_error_message(page)

            next if error_message.blank?

            OpenStruct.new(
              message: error_message,
              link: "##{self.class.page_error_id(page)}",
            )
          }.compact
        else
          @form.conditions.map { |condition|
            condition.validation_errors.map do |error|
              error_object(
                error_name: error.name,
                page: condition.check_page,
                condition: condition,
              )
            end
          }.flatten
        end
      end
    end
  end
end
