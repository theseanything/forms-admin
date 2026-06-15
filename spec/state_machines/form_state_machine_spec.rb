require "rails_helper"

class FakeForm < ApplicationRecord
  self.table_name = "forms"

  include FormStateMachine

  # stub the expected interface
  def all_ready_for_live?; end
  def can_make_english_version_live?; end
  def can_make_welsh_version_live?; end
  def after_create_draft; end
  def before_make_live; end
  def before_make_english_live; end
  def before_make_welsh_live; end
  def after_make_live; end
  def after_make_english_live; end
  def after_make_welsh_live; end
  def after_archive; end
end

RSpec.describe FormStateMachine do
  let(:form) { FakeForm.new }

  it "has a default state of 'draft'" do
    expect(form).to have_state(:draft)
  end

  describe ".delete_form event" do
    it "does not transition if form is not a draft" do
      expect(form).not_to transition_from(:live).to(:deleted).on_event(:delete_form)
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "transitions to deleted stated and is destroyed" do
        expect(form).to receive(:destroy!)
        expect(form).to transition_from(:draft).to(:deleted).on_event(:delete_form)
      end
    end
  end

  describe ".make_live" do
    shared_examples "transition to live state" do |form_state|
      before do
        allow(form).to receive_messages(all_ready_for_live?: true, before_make_live: nil, after_make_live: nil)
      end

      it "transitions to live state" do
        expect(form).to transition_from(form_state).to(:live).on_event(:make_live)
      end

      it "calls the before_make_live callback" do
        form.make_live
        expect(form).to have_received(:before_make_live)
      end

      it "calls the after_make_live callback" do
        form.make_live
        expect(form).to have_received(:after_make_live)
      end
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:draft).to(:live).on_event(:make_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :draft
      end
    end

    context "when form is live_with_draft" do
      let(:form) { FakeForm.new(state: :live_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:live_with_draft).to(:live).on_event(:make_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :live_with_draft
      end
    end

    context "when form is archived" do
      let(:form) { FakeForm.new(state: :archived) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived).to(:live).on_event(:make_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :archived
      end
    end

    context "when form is archived_with_draft" do
      let(:form) { FakeForm.new(state: :archived_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived_with_draft).to(:live).on_event(:make_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :archived_with_draft
      end
    end
  end

  describe ".make_english_version_live" do
    shared_examples "transition to live state" do |form_state|
      before do
        allow(form).to receive_messages(can_make_english_version_live?: true, before_make_english_live: nil, after_make_english_live: nil)
      end

      it "transitions to live state" do
        expect(form).to transition_from(form_state).to(:live).on_event(:make_english_version_live)
      end

      it "calls the before_make_english_live callback" do
        form.make_english_version_live
        expect(form).to have_received(:before_make_english_live)
      end

      it "calls the after_make_english_live callback" do
        form.make_english_version_live
        expect(form).to have_received(:after_make_english_live)
      end
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:draft).to(:live).on_event(:make_english_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :draft
      end
    end

    context "when form is live" do
      let(:form) { FakeForm.new(state: :live) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:live).to(:live).on_event(:make_english_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :live
      end
    end

    context "when form is live_with_draft" do
      let(:form) { FakeForm.new(state: :live_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:live_with_draft).to(:live).on_event(:make_english_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :live_with_draft
      end
    end

    context "when form is archived" do
      let(:form) { FakeForm.new(state: :archived) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived).to(:live).on_event(:make_english_version_live)
      end

      context "when all sections are completed" do
        before do
          allow(form).to receive_messages(can_make_english_version_live?: true, before_make_english_live: nil, after_make_english_live: nil)
        end

        it "does not transition to live state" do
          expect(form).not_to transition_from(:archived).to(:live).on_event(:make_english_version_live)
        end
      end
    end

    context "when form is archived_with_draft" do
      let(:form) { FakeForm.new(state: :archived_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived_with_draft).to(:live).on_event(:make_english_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :archived_with_draft
      end
    end
  end

  describe ".make_welsh_version_live" do
    shared_examples "transition to live state" do |form_state|
      before do
        allow(form).to receive_messages(can_make_welsh_version_live?: true, before_make_welsh_live: nil, after_make_welsh_live: nil)
      end

      it "transitions to live state" do
        expect(form).to transition_from(form_state).to(:live).on_event(:make_welsh_version_live)
      end

      it "calls the before_make_welsh_live callback" do
        form.make_welsh_version_live
        expect(form).to have_received(:before_make_welsh_live)
      end

      it "calls the after_make_welsh_live callback" do
        form.make_welsh_version_live
        expect(form).to have_received(:after_make_welsh_live)
      end
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived).to(:live).on_event(:make_welsh_version_live)
      end

      context "when all sections are completed" do
        before do
          allow(form).to receive_messages(can_make_welsh_version_live?: true, before_make_welsh_live: nil, after_make_welsh_live: nil)
        end

        it "does not transition to live state" do
          expect(form).not_to transition_from(:archived).to(:live).on_event(:make_welsh_version_live)
        end
      end
    end

    context "when form is live_with_draft" do
      let(:form) { FakeForm.new(state: :live_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:live_with_draft).to(:live).on_event(:make_welsh_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :live_with_draft
      end
    end

    context "when form is live" do
      let(:form) { FakeForm.new(state: :live) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:live).to(:live).on_event(:make_welsh_version_live)
      end

      context "when all sections are completed" do
        it_behaves_like "transition to live state", :live
      end
    end

    context "when form is archived" do
      let(:form) { FakeForm.new(state: :archived) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived).to(:live).on_event(:make_welsh_version_live)
      end

      context "when all sections are completed" do
        before do
          allow(form).to receive_messages(can_make_welsh_version_live?: true, before_make_welsh_live: nil, after_make_welsh_live: nil)
        end

        it "does not transition to live state" do
          expect(form).not_to transition_from(:archived).to(:live).on_event(:make_welsh_version_live)
        end
      end
    end

    context "when form is archived_with_draft" do
      let(:form) { FakeForm.new(state: :archived_with_draft) }

      it "does not transition to live state by default" do
        expect(form).not_to transition_from(:archived_with_draft).to(:live).on_event(:make_welsh_version_live)
      end

      context "when all sections are completed" do
        before do
          allow(form).to receive_messages(can_make_english_version_live?: true, before_make_english_live: nil, after_make_english_live: nil)
        end

        it "does not transition to live state" do
          expect(form).not_to transition_from(:archived).to(:live).on_event(:make_welsh_version_live)
        end
      end
    end
  end

  describe ".create_draft_from_live_form" do
    let(:form) { FakeForm.new(state: :live) }

    before do
      allow(form).to receive(:after_create_draft)
    end

    it "transitions to live_with_draft if form is live" do
      expect(form).to transition_from(:live).to(:live_with_draft).on_event(:create_draft_from_live_form)
    end

    it "calls the after_create_draft callback" do
      form.create_draft_from_live_form
      expect(form).to have_received :after_create_draft
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to live_with_draft" do
        expect(form).not_to transition_from(:draft).to(:live_with_draft).on_event(:create_draft_from_live_form)
      end

      it "does not call the after_create_draft callback" do
        expect { form.create_draft_from_live_form }.to raise_error AASM::InvalidTransition
        expect(form).not_to have_received :after_create_draft
      end
    end
  end

  describe ".create_draft_from_archived_form" do
    let(:form) { FakeForm.new(state: :archived) }

    before do
      allow(form).to receive(:after_create_draft)
    end

    it "transitions to archived_with_draft" do
      expect(form).to transition_from(:archived).to(:archived_with_draft).on_event(:create_draft_from_archived_form)
    end

    it "calls the after_create_draft callback" do
      form.create_draft_from_archived_form
      expect(form).to have_received :after_create_draft
    end

    context "when form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to archived_with_draft" do
        expect(form).not_to transition_from(:draft).to(:archived_with_draft).on_event(:create_draft_from_archived_form)
      end

      it "does not call the after_create_draft callback" do
        expect { form.create_draft_from_archived_form }.to raise_error AASM::InvalidTransition
        expect(form).not_to have_received :after_create_draft
      end
    end
  end

  describe ".archive_live_form" do
    context "when the form is draft" do
      let(:form) { FakeForm.new(state: :draft) }

      it "does not transition to archived" do
        expect(form).not_to transition_from(:draft).to(:archived).on_event(:archive_live_form)
      end
    end

    context "when the form is live" do
      let(:form) { FakeForm.new(state: :live) }

      before do
        allow(form).to receive(:after_archive)
      end

      it "transitions to archived" do
        expect(form).to transition_from(:live).to(:archived).on_event(:archive_live_form)
      end

      it "calls the after_archive callback" do
        form.archive_live_form
        expect(form).to have_received(:after_archive)
      end
    end

    context "when form is live_with_draft" do
      let(:form) { FakeForm.new(state: :live_with_draft) }

      before do
        allow(form).to receive(:after_archive)
      end

      it "transitions to archived_with_draft" do
        expect(form).to transition_from(:live_with_draft).to(:archived_with_draft).on_event(:archive_live_form)
      end

      it "calls the FormDocumentSyncService" do
        form.archive_live_form
        expect(form).to have_received(:after_archive)
      end
    end
  end

  describe ".event_path" do
    it "returns the event for a state one transition away" do
      expect(FakeForm.event_path(from: :live, to: :archived))
        .to eq %i[archive_live_form]
    end

    it "returns the events to fire in order when the target state needs intermediate transitions" do
      # no event goes directly from draft to archived, so the form has to be
      # made live on the way
      expect(FakeForm.event_path(from: :draft, to: :archived))
        .to eq %i[make_live archive_live_form]
    end

    it "returns the events to fire in order when the target state needs two intermediate transitions" do
      # reaching archived_with_draft from draft means passing through both the
      # live and live_with_draft states
      expect(FakeForm.event_path(from: :draft, to: :archived_with_draft))
        .to eq %i[make_live create_draft_from_live_form archive_live_form]
    end

    it "returns the shortest sequence of events when there is more than one route" do
      # an archived_with_draft form could reach archived by being made live
      # and archived again, but deleting its draft gets there in one transition
      expect(FakeForm.event_path(from: :archived_with_draft, to: :archived))
        .to eq %i[delete_draft_from_archived_form]
    end

    it "returns an empty path when the form is already in the target state" do
      expect(FakeForm.event_path(from: :live, to: :live)).to eq []
    end

    it "returns nil when no sequence of events reaches the target state" do
      # no event transitions a form back to draft once it has been made live
      expect(FakeForm.event_path(from: :live, to: :draft)).to be_nil
    end

    it "never routes through the delete_form event" do
      # delete_form is the only transition into the deleted state, but firing
      # it would destroy the form, so deleted is treated as unreachable
      expect(FakeForm.event_path(from: :draft, to: :deleted)).to be_nil
    end

    it "never routes through the language-specific live events" do
      # make_english_version_live also transitions from draft to live, but it
      # publishes only one translation, so the path uses make_live
      expect(FakeForm.event_path(from: :draft, to: :live)).to eq %i[make_live]
    end
  end
end
