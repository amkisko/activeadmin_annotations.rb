# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::ReviewAccess do
  let(:reviewer) { create(:user) }
  let(:other_reviewer) { create(:user) }
  let(:review) { create(:annotation_review, reviewer: reviewer) }

  describe ".review_for_span_create!" do
    it "returns the review when the reviewer owns it" do
      result = described_class.review_for_span_create!(review_id: review.id, reviewer: reviewer)

      expect(result).to eq(review)
    end

    it "rejects a missing review id", :aggregate_failures do
      expect do
        described_class.review_for_span_create!(review_id: nil, reviewer: reviewer)
      end.to raise_error(described_class::NotFound, /not found/)

      expect do
        described_class.review_for_span_create!(review_id: SecureRandom.uuid, reviewer: reviewer)
      end.to raise_error(described_class::NotFound, /not found/)
    end

    it "rejects a review owned by another reviewer" do
      expect do
        described_class.review_for_span_create!(review_id: review.id, reviewer: other_reviewer)
      end.to raise_error(described_class::Forbidden, /access denied/)
    end

    it "rejects a missing reviewer" do
      expect do
        described_class.review_for_span_create!(review_id: review.id, reviewer: nil)
      end.to raise_error(described_class::Forbidden, /access denied/)
    end
  end

  describe ".authorize_annotation!" do
    let(:annotation) { create(:annotation, annotation_review: review) }

    it "returns the annotation when the reviewer owns the review" do
      result = described_class.authorize_annotation!(annotation: annotation, reviewer: reviewer)

      expect(result).to eq(annotation)
    end

    it "rejects an annotation on another reviewer's review" do
      expect do
        described_class.authorize_annotation!(annotation: annotation, reviewer: other_reviewer)
      end.to raise_error(described_class::Forbidden, /access denied/)
    end
  end
end
