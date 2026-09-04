# frozen_string_literal: true

module ActiveAdmin::Annotations
  class ReviewService
    class << self
      def preview_review(**kwargs)
        assemble_review!(**kwargs, persist: false)
      end

      def find_or_sync_review!(
        subject:,
        reviewer:,
        context:,
        context_digest: nil,
        content_revision_version: 0,
        latest_content_revision_version: content_revision_version,
        content_revision_enabled: ContentRevision.enabled_for?(subject)
      )
        2.times do |attempt|
          return sync_and_save_review!(
            subject: subject,
            reviewer: reviewer,
            context: context,
            context_digest: context_digest,
            content_revision_version: content_revision_version,
            latest_content_revision_version: latest_content_revision_version,
            content_revision_enabled: content_revision_enabled
          )
        rescue ActiveRecord::RecordNotUnique
          raise if attempt == 1
        end
      end

      def advance_to_latest!(
        subject:,
        reviewer:,
        context:,
        latest_content_revision_version:, context_digest: nil,
        content_revision_enabled: ContentRevision.enabled_for?(subject)
      )
        raise ArgumentError, "content revisions are not enabled for this subject" unless content_revision_enabled

        review = Review.find_by!(subject: subject, reviewer: reviewer)
        context_hash = context.deep_stringify_keys
        digest = context_digest.presence || Context.digest_for(context_hash)
        latest_version = latest_content_revision_version.to_i

        review.update!(
          content_revision_version: latest_version,
          context_json: context_hash,
          context_digest: digest,
          metadata_json: review.metadata_json.to_h.merge("context_stale" => false)
        )
        review
      end

      private

      def sync_and_save_review!(**kwargs)
        assemble_review!(**kwargs, persist: true)
      end

      def assemble_review!(
        subject:,
        reviewer:,
        context:,
        persist:,
        context_digest: nil,
        content_revision_version: 0,
        latest_content_revision_version: content_revision_version,
        content_revision_enabled: ContentRevision.enabled_for?(subject)
      )
        context_hash = context.deep_stringify_keys
        digest = context_digest.presence || Context.digest_for(context_hash)
        pinned_version = content_revision_version.to_i
        latest_version = latest_content_revision_version.to_i

        review = Review.find_or_initialize_by(
          subject: subject,
          reviewer: reviewer
        )

        if content_revision_enabled
          sync_with_content_revision!(
            review,
            context_hash: context_hash,
            digest: digest,
            pinned_version: pinned_version,
            latest_version: latest_version
          )
        else
          sync_without_content_revision!(review, context_hash: context_hash, digest: digest)
        end

        review.save! if persist
        review
      end

      def sync_with_content_revision!(review, context_hash:, digest:, pinned_version:, latest_version:)
        if review.new_record?
          review.assign_attributes(
            content_revision_version: pinned_version,
            context_json: context_hash,
            context_digest: digest,
            metadata_json: review.metadata_json.to_h.merge("context_stale" => false)
          )
        elsif latest_version > review.content_revision_version
          review.metadata_json = review.metadata_json.to_h.merge("context_stale" => true)
        elsif review.content_revision_version == pinned_version && review.context_digest != digest
          review.assign_attributes(
            context_json: context_hash,
            context_digest: digest,
            metadata_json: review.metadata_json.to_h.merge("context_stale" => false)
          )
        elsif !review.context_stale?
          review.metadata_json = review.metadata_json.to_h.merge("context_stale" => false)
        end
      end

      def sync_without_content_revision!(review, context_hash:, digest:)
        if review.new_record?
          review.assign_attributes(
            content_revision_version: 0,
            context_json: context_hash,
            context_digest: digest,
            metadata_json: review.metadata_json.to_h.merge("context_stale" => false)
          )
        elsif review.context_digest != digest
          review.metadata_json = review.metadata_json.to_h.merge("context_stale" => true)
        else
          review.assign_attributes(
            context_json: context_hash,
            context_digest: digest,
            metadata_json: review.metadata_json.to_h.merge("context_stale" => false)
          )
        end
      end
    end
  end
end
