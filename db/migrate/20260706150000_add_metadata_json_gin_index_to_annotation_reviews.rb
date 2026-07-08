# frozen_string_literal: true

class AddMetadataJsonGinIndexToAnnotationReviews < ActiveRecord::Migration[8.1]
  def change
    return unless connection.adapter_name.match?(/postgres/i)

    add_index :annotation_reviews, :metadata_json, using: :gin, if_not_exists: true
  end
end
