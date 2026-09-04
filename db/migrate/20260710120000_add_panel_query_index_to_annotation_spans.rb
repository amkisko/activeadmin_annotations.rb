# frozen_string_literal: true

class AddPanelQueryIndexToAnnotationSpans < ActiveRecord::Migration[7.1]
  def change
    add_index :annotation_spans,
      %i[annotation_review_id field_name content_revision_version],
      name: "index_annotation_spans_on_review_field_and_revision",
      if_not_exists: true
  end
end
