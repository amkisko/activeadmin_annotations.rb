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

  describe ".subject_for_span_create!" do
    let(:document) { create(:document) }

    it "returns the subject when the type and id match" do
      result = described_class.subject_for_span_create!(subject_type: "Document", subject_id: document.id)

      expect(result).to eq(document)
    end

    it "rejects a missing or unknown subject", :aggregate_failures do
      expect do
        described_class.subject_for_span_create!(subject_type: nil, subject_id: document.id)
      end.to raise_error(described_class::NotFound, "Subject not found")

      expect do
        described_class.subject_for_span_create!(subject_type: "Kernel", subject_id: document.id)
      end.to raise_error(described_class::NotFound, "Subject not found")

      expect do
        described_class.subject_for_span_create!(subject_type: "Document", subject_id: SecureRandom.uuid)
      end.to raise_error(described_class::NotFound, "Subject not found")
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

    it "rejects a missing annotation" do
      expect do
        described_class.authorize_annotation!(annotation: nil, reviewer: reviewer)
      end.to raise_error(described_class::NotFound, "Annotation not found")
    end
  end
end
