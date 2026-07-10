# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::ReviewService do
  let(:reviewer) { create(:user) }
  let(:document) { create(:document, body: "Original summary") }
  let(:context) do
    {
      "output" => {
        "headline" => "Week",
        "summary_markdown" => document.body
      }
    }
  end

  describe ".find_or_sync_review!" do
    it "creates a review for a new subject and reviewer", :aggregate_failures do
      review = described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: context,
        content_revision_enabled: false
      )

      expect(review).to be_persisted
      expect(review.context_json).to eq(context)
      expect(review.context_stale?).to be(false)
    end

    it "marks the review stale on context digest changes when revisions are disabled", :aggregate_failures do
      review = described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: context,
        content_revision_enabled: false
      )
      original_context = review.context_json

      new_context = context.merge("output" => context["output"].merge("summary_markdown" => "Regenerated summary"))

      described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: new_context,
        content_revision_enabled: false
      )

      review.reload
      expect(review.context_stale?).to be(true)
      expect(review.context_json).to eq(original_context)
    end

    it "reuses an existing review for the same subject and reviewer", :aggregate_failures do
      existing = create(:annotation_review, subject: document, reviewer: reviewer)

      review = described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: context,
        content_revision_enabled: false
      )

      expect(review.id).to eq(existing.id)
      expect(ActiveAdmin::Annotations::Review.where(subject: document, reviewer: reviewer).count).to eq(1)
    end

    it "retries once after a concurrent create hits the unique index" do
      attempts = 0
      allow(described_class).to receive(:sync_and_save_review!).and_wrap_original do |method, **kwargs|
        attempts += 1
        raise ActiveRecord::RecordNotUnique if attempts == 1

        method.call(**kwargs)
      end

      review = described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: context,
        content_revision_enabled: false
      )

      expect(attempts).to eq(2)
      expect(review).to be_persisted
    end

    it "marks the review stale when a newer content revision exists", :aggregate_failures do
      ActiveAdmin::Annotations.content_revision_strategy = :auto
      ActiveAdmin::Annotations.current_content_revision_version = ->(subject) { subject.revision_version }

      create(:annotation_review, subject: document, reviewer: reviewer, content_revision_version: 0)
      document.update!(revision_version: 2)

      review = described_class.find_or_sync_review!(
        subject: document,
        reviewer: reviewer,
        context: context,
        content_revision_version: 0,
        latest_content_revision_version: 2,
        content_revision_enabled: true
      )

      expect(review.context_stale?).to be(true)
      expect(review.content_revision_version).to eq(0)
    end
  end

  describe ".advance_to_latest!" do
    around do |example|
      original_strategy = ActiveAdmin::Annotations.content_revision_strategy
      original_current = ActiveAdmin::Annotations.current_content_revision_version
      example.run
    ensure
      ActiveAdmin::Annotations.content_revision_strategy = original_strategy
      ActiveAdmin::Annotations.current_content_revision_version = original_current
    end

    before do
      ActiveAdmin::Annotations.content_revision_strategy = :auto
      ActiveAdmin::Annotations.current_content_revision_version = ->(subject) { subject.revision_version }
    end

    it "raises when revisions are disabled" do
      ActiveAdmin::Annotations.content_revision_strategy = :none

      expect do
        described_class.advance_to_latest!(
          subject: document,
          reviewer: reviewer,
          context: context,
          latest_content_revision_version: 0,
          content_revision_enabled: false
        )
      end.to raise_error(ArgumentError, /not enabled/)
    end

    it "moves the review to the latest revision and clears stale metadata", :aggregate_failures do
      review = create(
        :annotation_review,
        subject: document,
        reviewer: reviewer,
        content_revision_version: 1,
        metadata_json: {"context_stale" => true}
      )
      document.update!(revision_version: 2)
      new_context = context.merge("output" => context["output"].merge("summary_markdown" => "Updated summary"))

      result = described_class.advance_to_latest!(
        subject: document,
        reviewer: reviewer,
        context: new_context,
        latest_content_revision_version: 2,
        content_revision_enabled: true
      )

      expect(result.id).to eq(review.id)
      expect(result.content_revision_version).to eq(2)
      expect(result.context_stale?).to be(false)
      expect(result.context_json).to eq(new_context.deep_stringify_keys)
    end
  end
end
