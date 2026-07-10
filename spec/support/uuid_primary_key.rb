# frozen_string_literal: true

module UuidPrimaryKey
  extend ActiveSupport::Concern

  included do
    before_validation :assign_uuid_primary_key, on: :create
  end

  def assign_uuid_primary_key
    return unless has_attribute?(:id)

    self.id = SecureRandom.uuid if id.blank?
  end
end

ApplicationRecord.include(UuidPrimaryKey)

ActiveAdmin::Annotations::ApplicationRecord.include(UuidPrimaryKey)
