# frozen_string_literal: true

module ActiveAdmin::Annotations
  class ReviewPanel
    def self.render(**kwargs)
      new(**kwargs).render
    end

    def initialize(
      subject:,
      reviewer:,
      field:,
      view_context:,
      context_builder:,
      content_builder:,
      context_panels_builder: nil,
      advance_review_url: nil,
      categories: nil,
      category_label: nil,
      content_revision_enabled: nil,
      viewing_content_revision_version: nil
    )
      @subject = subject
      @reviewer = reviewer
      @field = field.to_s
      @view_context = view_context
      @context_builder = context_builder
      @content_builder = content_builder
      @context_panels_builder = context_panels_builder
      @advance_review_url = advance_review_url
      @categories = categories
      @category_label = category_label
      @content_revision_enabled = content_revision_enabled
      @viewing_content_revision_version = viewing_content_revision_version
    end

    def render
      revision_enabled = @content_revision_enabled.nil? ? ContentRevision.enabled_for?(@subject) : @content_revision_enabled
      latest_version = revision_enabled ? ContentRevision.current_version_for(@subject) : 0
      browsing_revision = @viewing_content_revision_version.present?

      if browsing_revision
        render_browsed_revision(
          revision_enabled: revision_enabled,
          latest_version: latest_version,
          display_version: @viewing_content_revision_version.to_i.clamp(0, latest_version)
        )
      else
        render_review_revision(revision_enabled: revision_enabled, latest_version: latest_version)
      end
    end

    private

    def render_browsed_revision(revision_enabled:, latest_version:, display_version:)
      content_subject = revision_enabled ? ContentRevision.content_subject_for(@subject, display_version) : @subject
      review = Review.find_by(subject: @subject, reviewer: @reviewer)
      annotations = annotations_for_review(
        review: review,
        revision_enabled: revision_enabled,
        display_version: display_version
      )

      render_panel(
        review: review || Review.new(subject: @subject, reviewer: @reviewer, content_revision_version: display_version),
        content_subject: content_subject,
        revision_enabled: revision_enabled,
        latest_version: latest_version,
        display_version: display_version,
        annotations: annotations,
        content_stale: false,
        advance_review_url: nil,
        readonly: review.blank? || display_version != review.content_revision_version
      )
    end

    def render_review_revision(revision_enabled:, latest_version:)
      existing_review = Review.find_by(subject: @subject, reviewer: @reviewer)
      pinned_version = if revision_enabled
        existing_review&.content_revision_version || ContentRevision.current_version_for(@subject)
      else
        0
      end
      content_subject = revision_enabled ? ContentRevision.content_subject_for(@subject, pinned_version) : @subject
      context = @context_builder.call(content_subject)
      digest = Context.digest_for(context)

      review = ReviewService.preview_review(
        subject: @subject,
        reviewer: @reviewer,
        context: context,
        context_digest: digest,
        content_revision_version: pinned_version,
        latest_content_revision_version: latest_version,
        content_revision_enabled: revision_enabled
      )
      annotations = annotations_for_review(
        review: review,
        revision_enabled: revision_enabled,
        display_version: review.content_revision_version
      )

      render_panel(
        review: review,
        content_subject: content_subject,
        revision_enabled: revision_enabled,
        latest_version: latest_version,
        display_version: review.content_revision_version,
        annotations: annotations,
        content_stale: review.context_stale?,
        advance_review_url: revision_enabled ? @advance_review_url : nil,
        readonly: false
      )
    end

    def render_panel(review:, content_subject:, revision_enabled:, latest_version:, display_version:, annotations:, content_stale:, advance_review_url:, readonly: false)
      context = @context_builder.call(content_subject)

      @view_context.helpers.activeadmin_annotations_panel(
        subject: @subject,
        field: @field,
        context: context,
        context_digest: Context.digest_for(context),
        content_revision_enabled: revision_enabled,
        content_revision_version: display_version,
        latest_content_revision_version: latest_version,
        content_stale: content_stale,
        advance_review_url: advance_review_url,
        context_panels: @context_panels_builder&.call(content_subject) || [],
        content: @content_builder.call(content_subject),
        annotations: annotations,
        review: review,
        categories: @categories,
        category_label: @category_label,
        readonly: readonly
      )
    end

    def annotations_for_review(review:, revision_enabled:, display_version:)
      return [] unless review&.persisted?

      scope = review.annotations.where(field_name: @field).order(:created_at)
      return scope unless revision_enabled

      scope.where(content_revision_version: display_version)
    end
  end
end
