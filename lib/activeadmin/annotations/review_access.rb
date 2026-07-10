# frozen_string_literal: true

module ActiveAdmin::Annotations
  module ReviewAccess
    class Error < StandardError; end

    class NotFound < Error; end

    class Forbidden < Error; end

    def self.review_for_span_create!(review_id:, reviewer:)
      raise NotFound, "Review not found" if review_id.blank?

      review = Review.find_by(id: review_id)
      raise NotFound, "Review not found" unless review
      raise Forbidden, "Review not found" unless reviewer.present? && review.reviewer_id == reviewer.id

      review
    end

    def self.authorize_annotation!(annotation:, reviewer:)
      raise Forbidden, "Annotation not found" unless annotation
      raise Forbidden, "Annotation not found" unless reviewer.present? &&
        annotation.annotation_review.reviewer_id == reviewer.id

      annotation
    end
  end
end
