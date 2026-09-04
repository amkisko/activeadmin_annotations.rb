# frozen_string_literal: true

class CreateActiveadminAnnotationsTables < ActiveRecord::Migration[7.1]
  def change
    enable_pgcrypto_for_postgres

    json_column_type = postgres? ? :jsonb : :json
    uuid_column_type = postgres? ? :uuid : :string

    create_table :annotation_reviews, id: uuid_column_type do |t|
      t.references :subject, polymorphic: true, null: false, type: uuid_column_type, index: true
      t.column :reviewer_id, uuid_column_type, null: false
      t.string :review_status, null: false, default: "pending"
      t.text :notes
      t.send(json_column_type, :context_json, null: false, default: {})
      t.string :context_digest
      t.integer :content_revision_version, null: false, default: 0
      t.send(json_column_type, :metadata_json, null: false, default: {})

      t.timestamps
    end

    add_index :annotation_reviews, %i[subject_type subject_id reviewer_id], unique: true, name: "index_annotation_reviews_on_subject_and_reviewer"
    add_index :annotation_reviews, :review_status
    add_index :annotation_reviews, :context_digest
    add_index :annotation_reviews, :reviewer_id

    create_table :annotation_spans, id: uuid_column_type do |t|
      t.references :annotation_review, null: false, type: uuid_column_type, foreign_key: {to_table: :annotation_reviews}, index: true
      t.string :field_name, null: false
      t.text :selected_text, null: false
      t.integer :start_offset, null: false
      t.integer :end_offset, null: false
      t.text :comment, null: false
      t.string :category
      t.integer :content_revision_version, null: false, default: 0
      t.send(json_column_type, :context_paths_json, null: false, default: [])
      t.send(json_column_type, :metadata_json, null: false, default: {})

      t.timestamps
    end

    add_index :annotation_spans, :category
    add_index :annotation_spans, :field_name
  end

  private

  def enable_pgcrypto_for_postgres
    return unless postgres?

    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")
  end

  def postgres?
    connection.adapter_name.match?(/postgres/i)
  end
end
