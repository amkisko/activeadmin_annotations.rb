# frozen_string_literal: true

class ActiveAdmin::Annotations::Annotation < ActiveAdmin::Annotations::ApplicationRecord
  self.table_name = "annotation_spans"

  belongs_to :annotation_review,
    class_name: "ActiveAdmin::Annotations::Review",
    inverse_of: :annotations

  validates :field_name, :selected_text, :comment, presence: true
  validates :start_offset, :end_offset, numericality: {greater_than_or_equal_to: 0}
  validate :end_offset_after_start_offset
  validate :category_must_be_allowed

  def self.ransackable_attributes(_auth_object = nil)
    %w[annotation_review_id field_name category comment created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[annotation_review]
  end

  private

  def end_offset_after_start_offset
    return if start_offset.blank? || end_offset.blank?
    return if end_offset >= start_offset

    errors.add(:end_offset, "must be greater than or equal to start offset")
  end

  def category_must_be_allowed
    return if ActiveAdmin::Annotations::Categories.allowed?(category)

    errors.add(:category, "is invalid")
  end
end
