# frozen_string_literal: true

class ActiveAdmin::Annotations::Review < ActiveAdmin::Annotations::ApplicationRecord
  self.table_name = "annotation_reviews"

  REVIEW_STATUSES = %w[pending reviewed escalated].freeze

  belongs_to :subject, polymorphic: true
  belongs_to :reviewer, class_name: ActiveAdmin::Annotations.reviewer_class_name

  has_many :annotations,
    class_name: "ActiveAdmin::Annotations::Annotation",
    foreign_key: :annotation_review_id,
    inverse_of: :annotation_review,
    dependent: :destroy

  validates :review_status, inclusion: {in: REVIEW_STATUSES}
  validates :reviewer_id, uniqueness: {scope: %i[subject_type subject_id]}
  validates :context_json, presence: true

  scope :pending, -> { where(review_status: "pending") }
  scope :reviewed, -> { where(review_status: "reviewed") }
  scope :escalated, -> { where(review_status: "escalated") }
  scope :needs_follow_up, lambda {
    if connection.adapter_name.match?(/postgres/i)
      where("metadata_json @> ?", {needs_follow_up: true}.to_json)
    else
      where("json_extract(metadata_json, '$.needs_follow_up') = ?", true)
    end
  }

  def needs_follow_up?
    metadata_flag("needs_follow_up")
  end

  def context_stale?
    metadata_flag("context_stale")
  end

  def metadata_flag(key)
    ActiveModel::Type::Boolean.new.cast(metadata_json.to_h[key]) == true
  end
  private :metadata_flag

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      subject_type
      subject_id
      reviewer_id
      review_status
      context_digest
      created_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[reviewer subject annotations]
  end
end
