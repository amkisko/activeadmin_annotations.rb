# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_260_710_120_000) do
  create_table :users, id: :uuid, force: :cascade do |t|
    t.string :email
    t.timestamps
  end

  create_table :documents, id: :uuid, force: :cascade do |t|
    t.text :body
    t.integer :revision_version, null: false, default: 0
    t.timestamps
  end

  create_table :annotation_reviews, id: :uuid, force: :cascade do |t|
    t.references :subject, polymorphic: true, null: false, type: :uuid, index: true
    t.string :reviewer_id, null: false
    t.string :review_status, null: false, default: "pending"
    t.text :notes
    t.json :context_json, null: false, default: {}
    t.string :context_digest
    t.integer :content_revision_version, null: false, default: 0
    t.json :metadata_json, null: false, default: {}

    t.timestamps
  end

  add_index :annotation_reviews, %i[subject_type subject_id reviewer_id],
    unique: true, name: "index_annotation_reviews_on_subject_and_reviewer"
  add_index :annotation_reviews, :review_status
  add_index :annotation_reviews, :context_digest
  add_index :annotation_reviews, :reviewer_id

  create_table :annotation_spans, id: :uuid, force: :cascade do |t|
    t.references :annotation_review, null: false, type: :uuid,
      foreign_key: {to_table: :annotation_reviews}, index: true
    t.string :field_name, null: false
    t.text :selected_text, null: false
    t.integer :start_offset, null: false
    t.integer :end_offset, null: false
    t.text :comment, null: false
    t.string :category
    t.integer :content_revision_version, null: false, default: 0
    t.json :context_paths_json, null: false, default: []
    t.json :metadata_json, null: false, default: {}

    t.timestamps
  end

  add_index :annotation_spans, :category
  add_index :annotation_spans, :field_name
  add_index :annotation_spans, %i[annotation_review_id field_name content_revision_version],
    name: "index_annotation_spans_on_review_field_and_revision"
end
