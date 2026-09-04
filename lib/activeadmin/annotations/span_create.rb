# frozen_string_literal: true

module ActiveAdmin::Annotations
  class SpanCreate
    class ReadOnly < StandardError; end

    def self.review_for!(params:, reviewer:)
      new(params: params, reviewer: reviewer).review
    end

    def initialize(params:, reviewer:)
      @params = params
      @reviewer = reviewer
    end

    def review
      resolved = existing_review_or_persist_from_subject
      reject_read_only!(resolved)
      resolved
    end

    private

    def existing_review_or_persist_from_subject
      review_id = annotation_hash[:annotation_review_id]
      if review_id.present?
        ReviewAccess.review_for_span_create!(review_id: review_id, reviewer: @reviewer)
      else
        persist_from_subject!
      end
    end

    def persist_from_subject!
      raise ReviewAccess::Forbidden, "Review access denied" if @reviewer.blank?

      subject = ReviewAccess.subject_for_span_create!(
        subject_type: annotation_hash[:subject_type],
        subject_id: annotation_hash[:subject_id]
      )
      revision_enabled = ContentRevision.enabled_for?(subject)
      ReviewService.find_or_sync_review!(
        subject: subject,
        reviewer: @reviewer,
        context: context_from_params,
        context_digest: annotation_hash[:context_digest],
        content_revision_version: revision_enabled ? ContentRevision.current_version_for(subject) : 0,
        content_revision_enabled: revision_enabled
      )
    end

    def reject_read_only!(review)
      return unless annotation_hash.key?(:displayed_content_revision_version)
      return if annotation_hash[:displayed_content_revision_version].to_i == review.content_revision_version

      raise ReadOnly, "This version is read-only."
    end

    def context_from_params
      context = annotation_hash[:context_json].presence || {}
      context = context.to_unsafe_h if context.respond_to?(:to_unsafe_h)
      context
    end

    def annotation_hash
      raw = @params[:annotation] || @params["annotation"] || {}
      raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
      raw.respond_to?(:with_indifferent_access) ? raw.with_indifferent_access : raw
    end
  end
end
