##
# Takes a form (with pages and conditions) and builds an array of RouteInput objects
# based on the pages and conditions.
class Routes::BuildService
  END_OF_FORM_OPTION = [I18n.t("page_conditions.end_of_form"), Forms::RouteInput::END_OF_FORM_VALUE].freeze
  NONE_OF_THE_ABOVE_OPTION = DataStruct.new(value: :none_of_the_above.to_s, name: I18n.t("page_conditions.none_of_the_above"))

  attr_reader :form

  def initialize(form:)
    @form = form
  end

  def build_routes
    conditions_by_key = form.conditions.index_by do |c|
      [c.routing_page_id, c.answer_value.presence]
    end

    form.pages.flat_map do |page|
      if page.answer_type == "selection" && page.answer_settings.only_one_option == "true"
        build_routes_for_selection_page(page, conditions_by_key)
      else
        build_route_for_generic_page(page, conditions_by_key)
      end
    end
  end

  def options_for_page(page)
    next_page = form.next_page_after(page)

    return [] unless next_page

    # Don't include the current page in the options
    options_without_page = all_goto_options.reject { |_, value| value == page.id }

    # Replace the next page with the default option
    options_without_page.map do |name, value|
      if value == next_page.id
        ["Go to question #{page.position.next}", Forms::RouteInput::DEFAULT_VALUE]
      else
        [name, value]
      end
    end
  end

private

  def build_routes_for_selection_page(page, conditions_by_key)
    options = page.answer_settings&.selection_options || []

    options << NONE_OF_THE_ABOVE_OPTION if page.is_optional

    options.map.with_index(1) do |option, index|
      answer_value = option["value"]
      answer_value_label = answer_value == NONE_OF_THE_ABOVE_OPTION[:value] ? I18n.t("page_conditions.none_of_the_above") : option["name"]
      key = [page.id, answer_value]
      condition = conditions_by_key[key]

      Forms::RouteInput.new(
        id: condition&.id,
        page_id: page.id,
        page:,
        answer_value:,
        goto: goto_value_for(condition),
        goto_options: options_for_page(page),
        label: { text: "Option #{index}: #{answer_value_label}" },
      )
    end
  end

  def build_route_for_generic_page(page, conditions_by_key)
    key = [page.id, nil]
    condition = conditions_by_key[key]

    [
      Forms::RouteInput.new(
        id: condition&.id,
        page_id: page.id,
        page:,
        goto: goto_value_for(condition),
        goto_options: options_for_page(page),
        label: { text: "Go to", hidden: true },
      ),
    ]
  end

  def all_goto_options
    @all_goto_options ||= begin
      page_opts = form.pages.map { |p| ["#{p.position}. #{p.question_text}", p.id] }
      page_opts + [END_OF_FORM_OPTION]
    end
  end

  def goto_value_for(condition)
    return Forms::RouteInput::DEFAULT_VALUE unless condition

    if condition.skip_to_end?
      Forms::RouteInput::END_OF_FORM_VALUE
    else
      condition.goto_page_id
    end
  end
end
