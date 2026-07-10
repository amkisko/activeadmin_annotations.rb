# frozen_string_literal: true

require "json"

module ActiveAdmin::Annotations
  class CopyText
    def self.for(annotation)
      new(annotation).to_s
    end

    def initialize(annotation)
      @annotation = annotation
      @review = annotation.annotation_review
    end

    def to_s
      sections = []
      instructions = copy_instructions
      sections << instructions if instructions.present?
      sections << review_section
      sections << context_section
      sections << annotation_section
      sections.join("\n\n")
    end

    private

    attr_reader :annotation, :review

    def copy_instructions
      instructions = ActiveAdmin::Annotations.copy_instructions
      return if instructions.blank?
      return instructions.call(annotation, review) if instructions.respond_to?(:call)

      instructions.to_s
    end

    def review_section
      lines = [
        "Review",
        "Subject: #{review.subject_type} ##{review.subject_id}",
        "Status: #{review.review_status}",
        "Reviewer ID: #{review.reviewer_id}",
        "Review ID: #{review.id}"
      ]
      if content_revision_enabled?
        lines.insert(2, "Content revision version: #{review.content_revision_version}")
      end
      lines << "Notes: #{review.notes}" if review.notes.present?
      lines << "Context digest: #{review.context_digest}" if review.context_digest.present?
      lines.join("\n")
    end

    def context_section
      "Context:\n#{JSON.pretty_generate(review.context_json.to_h)}"
    end

    def annotation_section
      category_label = ActiveAdmin::Annotations.category_label
      category_value = category_label_for(annotation.category)
      context_paths = Array(annotation.context_paths_json)

      lines = [
        "Annotation",
        "Annotation ID: #{annotation.id}",
        "Field: #{annotation.field_name}",
        "Selected text:\n#{annotation.selected_text}",
        "Comment:\n#{annotation.comment}",
        "#{category_label}: #{category_value}",
        "Span: #{annotation.start_offset}-#{annotation.end_offset}"
      ]
      lines << if context_paths.any?
        "Context paths: #{context_paths.join(", ")}"
      else
        "Context paths: (none)"
      end
      lines << "Created: #{annotation.created_at&.iso8601}" if annotation.created_at
      lines << "Updated: #{annotation.updated_at&.iso8601}" if annotation.updated_at
      if content_revision_enabled?
        lines.insert(2, "Content revision version: #{annotation.content_revision_version}")
      end
      lines.join("\n")
    end

    def content_revision_enabled?
      subject = review.subject
      return false if subject.blank?

      ContentRevision.enabled_for?(subject)
    end

    def category_label_for(value)
      return "(none)" if value.blank?

      ActiveAdmin::Annotations.categories[value] || value
    end
  end
end
