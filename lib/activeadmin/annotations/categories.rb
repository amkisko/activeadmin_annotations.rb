# frozen_string_literal: true

module ActiveAdmin::Annotations
  module Categories
    def self.all
      ActiveAdmin::Annotations.categories
    end

    def self.allowed?(value)
      value.blank? || all.key?(value)
    end
  end
end
