# frozen_string_literal: true

module ActiveAdmin
  module Annotations
    class << self
      attr_accessor :reviewer_class_name,
        :review_menu_visible,
        :categories,
        :category_label,
        :copy_instructions,
        :content_revision_strategy,
        :current_content_revision_version,
        :content_subject_for_revision,
        :content_revision_label,
        :stale_content_review_message,
        :stale_context_message

      def reviewer_class
        reviewer_class_name.constantize
      end
    end

    self.reviewer_class_name = "User"
    self.review_menu_visible = ->(user) { user&.administrator? }
    self.categories = {}
    self.category_label = "Category"
    self.copy_instructions = nil
    self.content_revision_strategy = :auto
    self.current_content_revision_version = nil
    self.content_subject_for_revision = nil
    self.content_revision_label = "Content version %{version}"
    self.stale_content_review_message = <<~TEXT
      A newer content version is available. These annotations stay on version %{pinned_version} until you review the latest text.
    TEXT
    self.stale_context_message = "The reviewed content has changed since these annotations were saved."
  end
end
