# frozen_string_literal: true

module ActiveAdmin::Annotations
  module PanelHelper
    def activeadmin_annotations_panel(
      subject:,
      field:,
      context:,
      context_digest: nil,
      context_panels: [],
      categories: nil,
      category_label: nil,
      content: nil,
      content_revision_enabled: nil,
      content_revision_version: nil,
      latest_content_revision_version: nil,
      content_stale: false,
      advance_review_url: nil,
      annotations: nil,
      review: nil,
      readonly: false,
      &content_block
    )
      rendered_content = PanelHtml.prepare(content.presence || capture(&content_block))
      reviewer = current_activeadmin_annotations_reviewer
      unless reviewer
        return render partial: "active_admin/annotations/read_only_content",
          locals: {content: rendered_content}
      end

      revision_enabled = content_revision_enabled.nil? ? ContentRevision.enabled_for?(subject) : content_revision_enabled
      review ||= ReviewService.preview_review(
        subject: subject,
        reviewer: reviewer,
        context: context,
        context_digest: context_digest,
        content_revision_version: content_revision_version || 0,
        latest_content_revision_version: latest_content_revision_version || content_revision_version || 0,
        content_revision_enabled: revision_enabled
      )
      display_version = content_revision_version.nil? ? review.content_revision_version : content_revision_version.to_i
      annotations ||= annotations_for(review:, field:, revision_enabled:, display_version:)
      stale_message = stale_message_for(
        review: review,
        revision_enabled: revision_enabled,
        pinned_version: review.content_revision_version,
        latest_version: latest_content_revision_version || review.content_revision_version
      )

      render partial: "active_admin/annotations/panel",
        locals: {
          subject: subject,
          field: field.to_s,
          review: review,
          annotations: annotations,
          context: context,
          context_digest: context_digest || Context.digest_for(context),
          context_panels: context_panels,
          categories: categories || ActiveAdmin::Annotations.categories,
          category_label: category_label || ActiveAdmin::Annotations.category_label,
          content: rendered_content,
          content_revision_enabled: revision_enabled,
          content_revision_version: display_version,
          latest_content_revision_version: latest_content_revision_version || review.content_revision_version,
          content_revision_label: ContentRevision.version_label(display_version),
          content_stale: content_stale || review.context_stale?,
          stale_message: stale_message,
          advance_review_url: advance_review_url,
          readonly: readonly
        }
    end

    private

    def annotations_for(review:, field:, revision_enabled:, display_version:)
      return [] unless review&.persisted?

      scope = review.annotations.where(field_name: field.to_s).order(:created_at)
      return scope unless revision_enabled

      scope.where(content_revision_version: display_version)
    end

    def stale_message_for(review:, revision_enabled:, pinned_version:, latest_version:)
      return unless review.context_stale?

      if revision_enabled
        ContentRevision.stale_review_message(
          review: review,
          pinned_version: pinned_version,
          latest_version: latest_version
        )
      else
        ContentRevision.stale_context_message(review: review)
      end
    end

    def current_activeadmin_annotations_reviewer
      respond_to?(:current_user) ? current_user : nil
    end
  end
end
