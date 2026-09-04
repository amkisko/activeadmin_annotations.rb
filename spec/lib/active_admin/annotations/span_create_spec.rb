# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::SpanCreate do
  let(:reviewer) { create(:user) }
  let(:document) { create(:document) }

  it "returns an owned review when a review id is present" do
    review = create(:annotation_review, subject: document, reviewer: reviewer)

    result = described_class.review_for!(
      params: {annotation: {annotation_review_id: review.id}},
      reviewer: reviewer
    )

    expect(result).to eq(review)
  end

  it "persists a review from the subject when no review id is present", :aggregate_failures do
    result = nil

    expect do
      result = described_class.review_for!(
        params: {
          annotation: {
            subject_type: "Document",
            subject_id: document.id,
            context_json: {"body" => document.body},
            context_digest: "digest-1",
            displayed_content_revision_version: 0
          }
        },
        reviewer: reviewer
      )
    end.to change(ActiveAdmin::Annotations::Review, :count).by(1)

    expect(result).to be_persisted
    expect(result.subject).to eq(document)
    expect(result.reviewer).to eq(reviewer)
  end

  it "rejects create when the displayed version is not the pinned version" do
    review = create(
      :annotation_review,
      subject: document,
      reviewer: reviewer,
      content_revision_version: 1
    )

    expect do
      described_class.review_for!(
        params: {
          annotation: {
            annotation_review_id: review.id,
            displayed_content_revision_version: 0
          }
        },
        reviewer: reviewer
      )
    end.to raise_error(described_class::ReadOnly, "This version is read-only.")
  end
end
