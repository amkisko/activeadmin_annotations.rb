# frozen_string_literal: true

require "json"

module ActiveAdmin::Annotations
  class Exporter
    BATCH_SIZE = 100

    def initialize(reviews:)
      @reviews = reviews
    end

    def to_jsonl
      lines = []
      each_jsonl_row { |row| lines << JSON.generate(row) }
      return "" if lines.empty?

      "#{lines.join("\n")}\n"
    end

    def each_jsonl_row
      return enum_for(:each_jsonl_row) unless block_given?

      if reviews.is_a?(ActiveRecord::Relation)
        export_relation_in_batches { |row| yield row }
      else
        Array(reviews).each do |review|
          rows_for(review).each { |row| yield row }
        end
      end
    end

    private

    attr_reader :reviews

    def export_relation_in_batches
      reviews.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        ActiveRecord::Associations::Preloader.new(records: batch, associations: :annotations).call
        batch.each do |review|
          rows_for(review).each { |row| yield row }
        end
      end
    end

    def rows_for(review)
      context = review.context_json.to_h
      revision_enabled = ContentRevision.enabled_for?(review.subject)
      annotations_for(review).map do |annotation|
        {
          review_id: review.id,
          annotation_id: annotation.id,
          subject: {
            type: review.subject_type,
            id: review.subject_id
          },
          field: annotation.field_name,
          context: context,
          annotation: annotation_payload(annotation, revision_enabled: revision_enabled),
          review: review_payload(review, revision_enabled: revision_enabled)
        }
      end
    end

    def annotation_payload(annotation, revision_enabled:)
      payload = {
        selected_text: annotation.selected_text,
        comment: annotation.comment,
        category: annotation.category,
        start_offset: annotation.start_offset,
        end_offset: annotation.end_offset,
        context_paths: Array(annotation.context_paths_json)
      }
      payload[:content_revision_version] = annotation.content_revision_version if revision_enabled
      payload
    end

    def annotations_for(review)
      association = review.association(:annotations)
      if association.loaded?
        association.target.sort_by(&:created_at)
      else
        review.annotations.order(:created_at).to_a
      end
    end

    def review_payload(review, revision_enabled:)
      payload = {
        reviewer_id: review.reviewer_id,
        review_status: review.review_status,
        notes: review.notes,
        context_digest: review.context_digest,
        reviewed_at: review.updated_at&.iso8601
      }
      payload[:content_revision_version] = review.content_revision_version if revision_enabled
      payload
    end
  end
end
