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
      raise Forbidden, "Review access denied" unless reviewer.present? && review.reviewer_id == reviewer.id

      review
    end

    def self.subject_for_span_create!(subject_type:, subject_id:)
      raise NotFound, "Subject not found" if subject_type.blank? || subject_id.blank?

      klass = subject_type.to_s.safe_constantize
      raise NotFound, "Subject not found" unless klass.is_a?(Class) && klass < ActiveRecord::Base

      subject = klass.find_by(id: subject_id)
      raise NotFound, "Subject not found" unless subject

      subject
    end

    def self.authorize_annotation!(annotation:, reviewer:)
      raise NotFound, "Annotation not found" unless annotation
      raise Forbidden, "Annotation access denied" unless reviewer.present? &&
        annotation.annotation_review.reviewer_id == reviewer.id

      annotation
    end
  end
end
