# frozen_string_literal: true

module ActiveAdmin::Annotations
  module Annotatable
    extend ::ActiveSupport::Concern

    included do
      has_many :annotation_reviews,
        as: :subject,
        class_name: "ActiveAdmin::Annotations::Review",
        dependent: :destroy,
        inverse_of: :subject
    end
  end
end
