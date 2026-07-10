# frozen_string_literal: true

class ActiveAdmin::Annotations::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.ransackable_associations(_auth_object = nil)
    reflect_on_all_associations.map { |association| association.name.to_s }
  end

  def self.ransackable_attributes(_auth_object = nil)
    column_names
  end
end
