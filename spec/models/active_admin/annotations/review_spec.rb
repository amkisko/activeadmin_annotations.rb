# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::Review do
  describe "ransack" do
    it "allowlists attributes and associations used by ActiveAdmin", :aggregate_failures do
      expect(described_class.ransackable_attributes).to match_array(
        %w[subject_type subject_id reviewer_id review_status context_digest created_at]
      )
      expect(described_class.ransackable_associations).to match_array(%w[reviewer subject annotations])
    end
  end

  describe ".needs_follow_up" do
    it "returns reviews flagged in metadata_json" do
      flagged = create(:annotation_review, metadata_json: {"needs_follow_up" => true})
      create(:annotation_review, metadata_json: {"needs_follow_up" => false})

      expect(described_class.needs_follow_up).to contain_exactly(flagged)
    end
  end

  describe "validations" do
    it "requires one review per subject and reviewer", :aggregate_failures do
      review = create(:annotation_review)
      duplicate = build(:annotation_review, subject: review.subject, reviewer: review.reviewer)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:reviewer_id]).to be_present
    end
  end
end
