# frozen_string_literal: true

module ActiveAdmin::Annotations
  module ContentRevision
    class << self
      def enabled_for?(subject)
        case ActiveAdmin::Annotations.content_revision_strategy
        when false, :none
          false
        when true, :active_version
          active_version_subject?(subject) || custom_version_resolver?
        else
          custom_version_resolver? || active_version_subject?(subject)
        end
      end

      def current_version_for(subject)
        if custom_current_version
          return custom_current_version.call(subject).to_i
        end

        return subject.current_version.to_i if active_version_subject?(subject)

        0
      end

      def content_subject_for(subject, version)
        if custom_content_subject
          return custom_content_subject.call(subject, version.to_i)
        end

        if active_version_subject?(subject)
          return active_version_content_subject(subject, version.to_i)
        end

        subject
      end

      def stale_review_message(review:, pinned_version:, latest_version:)
        message = ActiveAdmin::Annotations.stale_content_review_message
        return if message.blank?

        if message.respond_to?(:call)
          return message.call(review, pinned_version:, latest_version:)
        end

        format(message.to_s, pinned_version:, latest_version:)
      end

      def stale_context_message(review:)
        message = ActiveAdmin::Annotations.stale_context_message
        return if message.blank?

        return message.call(review) if message.respond_to?(:call)

        message.to_s
      end

      def version_label(version)
        label = ActiveAdmin::Annotations.content_revision_label
        return if label == false

        if label.respond_to?(:call)
          return label.call(version.to_i)
        end

        format((label || "Content version %{version}").to_s, version: version.to_i)
      end

      private

      def custom_version_resolver?
        custom_current_version.present? || custom_content_subject.present?
      end

      def custom_current_version
        ActiveAdmin::Annotations.current_content_revision_version
      end

      def custom_content_subject
        ActiveAdmin::Annotations.content_subject_for_revision
      end

      def active_version_subject?(subject)
        subject.class.respond_to?(:has_revisions?) &&
          subject.class.has_revisions? &&
          subject.respond_to?(:current_version)
      end

      def active_version_content_subject(subject, requested_version)
        head_version = subject.current_version.to_i
        return subject if requested_version == head_version

        snapshot_version = requested_version + 1
        return subject.at_version(snapshot_version) if subject.respond_to?(:at_version) && subject.at_version(snapshot_version)

        subject
      end
    end
  end
end
