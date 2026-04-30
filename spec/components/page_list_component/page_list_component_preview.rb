class PageListComponent::PageListComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  # TODO: the :with_group trait for each form is only needed while the multiple_branches_enabled feature column is in
  # use - we can remove it once we remove the feature flag column
  def default
    pages = []
    form = build(:form, :with_group, id: 0, pages:)
    render(PageListComponent::View.new(pages:, form:))
  end

  def with_pages_and_no_conditions
    pages = [build(:page, id: 1, position: 1, question_text: "Enter your name", routing_conditions: []),
             build(:page, id: 2, position: 2, question_text: "What is your pet's phone number?", routing_conditions: []),
             build(:page, id: 3, position: 3, question_text: "How many pets do you own?", routing_conditions: [])]
    form = build(:form, :with_group, id: 0, pages:)
    render(PageListComponent::View.new(pages:, form:))
  end

  def with_pages_and_one_condition
    condition = (build :condition, id: 1, routing_page_id: 1, check_page_id: 1, answer_value: "Wales", goto_page_id: 3)
    pages = [build(:page, id: 1, position: 1, question_text: "Enter your name", routing_conditions: [condition]),
             build(:page, id: 2, position: 2, question_text: "What is your pet's phone number?", routing_conditions: []),
             build(:page, id: 3, position: 3, question_text: "How many pets do you own?", routing_conditions: [])]
    form = build(:form, :with_group, id: 0, pages:)

    # We need to build the records rather than create them so that we don't save them to the database when we view the
    # preview. However, this means that the associations aren't available so we need to manually set the associations
    # after we've built the conditions
    condition.routing_page = pages[0]
    condition.check_page = pages[0]
    condition.goto_page = pages[2]
    condition.form = form

    render(PageListComponent::View.new(pages:, form:))
  end

  def with_pages_and_multiple_conditions
    routing_conditions_1 = [(build :condition, id: 1, routing_page_id: 1, check_page_id: 1, answer_value: "Wales", goto_page_id: 3),
                            (build :condition, id: 2, routing_page_id: 1, check_page_id: 1, answer_value: "England", goto_page_id: 2)]
    routing_conditions_2 = [(build :condition, id: 3, routing_page_id: 2, check_page_id: 2, answer_value: "Wales", goto_page_id: 3),
                            (build :condition, id: 4, routing_page_id: 2, check_page_id: 2, answer_value: "England", goto_page_id: 2)]
    pages = [(build :page, id: 1, position: 1, question_text: "Enter your name", routing_conditions: routing_conditions_1),
             (build :page, id: 2, position: 2, question_text: "What is your pet's phone number?", routing_conditions: routing_conditions_2),
             (build :page, id: 3, position: 3, question_text: "How many pets do you own?", routing_conditions: [])]
    form = build(:form, :with_group, id: 0, pages:)

    # We need to build the records rather than create them so that we don't save them to the database when we view the
    # preview. However, this means that the associations aren't available so we need to manually set the associations
    # after we've built the conditions
    (routing_conditions_1 + routing_conditions_2).each do |condition|
      condition.routing_page = pages.select { |page| page.id == condition.routing_page_id }.first
      condition.check_page = pages.select { |page| page.id == condition.check_page_id }.first
      condition.goto_page = pages.select { |page| page.id == condition.goto_page_id }.first
      condition.form = form
    end

    render(PageListComponent::View.new(pages:, form:))
  end

  def with_pages_and_conditions_with_errors
    routing_conditions_1 = [(build :condition, id: 1, routing_page_id: 1, check_page_id: 1, goto_page_id: 3),
                            (build :condition, id: 2, routing_page_id: 1, check_page_id: 1, answer_value: "England"),
                            (build :condition, id: 3, routing_page_id: 1, check_page_id: 1),
                            (build :condition, id: 5, routing_page_id: 1, check_page_id: 1, answer_value: "Wales", goto_page_id: 2)]
    routing_conditions_2 = [build(:condition, id: 4, routing_page_id: 2, check_page_id: 2, answer_value: "England", goto_page_id: 1)]
    pages = [(build :page, id: 1, position: 1, question_text: "Enter your name", routing_conditions: routing_conditions_1),
             (build :page, id: 2, position: 2, question_text: "What is your pet's phone number?", routing_conditions: routing_conditions_2),
             (build :page, id: 3, position: 3, question_text: "How many pets do you own?", routing_conditions: [])]
    form = build(:form, :with_group, id: 1, pages:)

    # We need to build the records rather than create them so that we don't save them to the database when we view the
    # preview. However, this means that the associations aren't available so we need to manually set the associations
    # after we've built the conditions
    (routing_conditions_1 + routing_conditions_2).each do |condition|
      condition.routing_page = pages.select { |page| page.id == condition.routing_page_id }.first
      condition.check_page = pages.select { |page| page.id == condition.check_page_id }.first
      condition.goto_page = pages.select { |page| page.id == condition.goto_page_id }.first
      condition.form = form
    end

    render(PageListComponent::View.new(pages:, form:))
  end

  def with_multiple_branches
    routing_conditions_1 = [
      (build :condition, id: 1, routing_page_id: 1, check_page_id: nil, goto_page_id: 3, answer_value: "Wales"),
      (build :condition, id: 2, routing_page_id: 1, check_page_id: nil, goto_page_id: 4, answer_value: "England"),
      (build :condition, id: 3, routing_page_id: 1, check_page_id: nil, goto_page_id: 5, answer_value: "Scotland"),
    ]

    routing_conditions_2 = [build(:condition, id: 4, routing_page_id: 2, check_page_id: nil, answer_value: "Don't know", goto_page_id: nil, skip_to_end: true)]

    pages = [
      (build :page, id: 1, position: 1, question_text: "What country are you in?", routing_conditions: routing_conditions_1),
      (build :page, id: 2, position: 2, question_text: "What is your pet's phone number?", routing_conditions: routing_conditions_2),
      (build :page, id: 3, position: 3, question_text: "How many pets do you own?", routing_conditions: []),
      (build :page, id: 4, position: 4, question_text: "What kind of pet do you want?", routing_conditions: []),
    ]

    form = build(:form, :with_group, id: 1, pages:)
    form.group.multiple_branches_enabled = true

    (routing_conditions_1 + routing_conditions_2).each do |condition|
      condition.routing_page = pages.select { |page| page.id == condition.routing_page_id }.first
      condition.goto_page = pages.select { |page| page.id == condition.goto_page_id }.first
      condition.form = form
    end

    render(PageListComponent::View.new(pages:, form:))
  end
end
