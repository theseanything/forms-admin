module FormStateMachine
  extend ActiveSupport::Concern

  # delete_form destroys the form rather than just changing its state, and the
  # language-specific live events publish only one translation, so a path
  # between states must never fire them
  EXCLUDED_EVENTS = %i[delete_form make_english_version_live make_welsh_version_live].freeze

  class_methods do
    # Breadth-first search of the state machine for the shortest sequence of
    # events that takes a form from one state to another, so that all event
    # callbacks run along the way. Returns an array of event names to fire in
    # order, an empty array if the form is already in the target state, or nil
    # if no sequence of events reaches it. Event guards such as
    # all_ready_for_live? are not evaluated here; they are only checked when
    # the events are fired.
    def event_path(from:, to:)
      event_paths = { from => [] }
      queue = [from]

      while (state = queue.shift)
        return event_paths[state] if state == to

        aasm.events.each do |event|
          next if EXCLUDED_EVENTS.include?(event.name)

          event.transitions_from_state(state).each do |transition|
            next if event_paths.key?(transition.to)

            event_paths[transition.to] = event_paths[state] + [event.name]
            queue << transition.to
          end
        end
      end

      nil
    end
  end

  included do
    include AASM

    enum :state, {
      draft: "draft",
      deleted: "deleted",
      live: "live",
      live_with_draft: "live_with_draft",
      archived: "archived",
      archived_with_draft: "archived_with_draft",
    }

    aasm column: :state, enum: true, whiny_persistence: true do
      state :draft, initial: true
      state :deleted, :live, :live_with_draft, :archived, :archived_with_draft

      # May be able to remove this as we haven't been using it in the API
      event :delete_form do
        after do
          destroy!
        end

        transitions from: :draft, to: :deleted
      end

      event :make_live do
        before :before_make_live
        after :after_make_live

        transitions from: %i[draft live_with_draft archived archived_with_draft], to: :live, guard: :all_ready_for_live?
      end

      event :make_english_version_live do
        before :before_make_english_live
        after :after_make_english_live

        transitions from: %i[draft live live_with_draft archived_with_draft], to: :live_with_draft, guard: :can_make_english_version_live?
      end

      event :make_welsh_version_live do
        before :before_make_welsh_live
        after :after_make_welsh_live

        transitions from: %i[live live_with_draft], to: :live, guard: :can_make_welsh_version_live?
      end

      event :create_draft_from_live_form do
        after :after_create_draft

        transitions from: :live, to: :live_with_draft
      end

      event :create_draft_from_archived_form do
        after :after_create_draft

        transitions from: :archived, to: :archived_with_draft
      end

      event :archive_live_form do
        after :after_archive

        transitions from: :live, to: :archived
        transitions from: :live_with_draft, to: :archived_with_draft
      end

      event :delete_draft_from_live_form do
        transitions from: %i[live_with_draft live], to: :live
      end

      event :delete_draft_from_archived_form do
        transitions from: %i[archived_with_draft archived], to: :archived
      end
    end
  end
end
