# frozen_string_literal: true

require_relative "spec_helper"

ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
require "activeadmin_annotations"

DUMMY_ROOT = Rails.root unless defined?(DUMMY_ROOT)

require_relative "support/engine_schema"

ActiveRecord::Base.connection_pool.with_connection do |connection|
  next if connection.table_exists?(:annotation_reviews)

  EngineSchema.load!
end

require "rspec/rails"
require "factory_bot"
require "activeadmin"

ActiveAdmin.application.load_paths << ActiveAdmin::Annotations::Engine.root.join("admin").to_s

Rails.application.reload_routes!
ActiveAdmin.application.load!

require_relative "support/uuid_primary_key"

module AuthHelpers
  def sign_in(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryBot::Syntax::Methods
  config.include AuthHelpers, type: :request

  config.before do
    ActiveAdmin::Annotations.categories = {
      "overconfident_claim" => "Overconfident claim"
    }
    ActiveAdmin::Annotations.reviewer_class_name = "User"
    ActiveAdmin::Annotations.content_revision_strategy = :none
    ActiveAdmin::Annotations.current_content_revision_version = nil
    ActiveAdmin::Annotations.content_subject_for_revision = nil
    ActiveAdmin::Annotations.copy_instructions = nil
  end
end

FactoryBot.define do
  factory :document do
    body { "Summary body" }
    revision_version { 0 }
  end

  factory :user do
    sequence(:email) { |index| "reviewer-#{index}@example.com" }
  end

  factory :annotation_review, class: "ActiveAdmin::Annotations::Review" do
    association :subject, factory: :document
    association :reviewer, factory: :user
    review_status { "pending" }
    context_digest { "digest-1" }
    context_json do
      {
        "generation" => {"source_digest" => "digest-1"},
        "input" => {"daily_updates" => []},
        "output" => {"headline" => "Week", "summary_markdown" => "Summary body"}
      }
    end
  end

  factory :annotation, class: "ActiveAdmin::Annotations::Annotation" do
    annotation_review factory: %i[annotation_review]
    field_name { "summary_markdown" }
    selected_text { "Summary body" }
    start_offset { 0 }
    end_offset { 12 }
    comment { "Too confident for the evidence." }
    category { "overconfident_claim" }
    context_paths_json { [] }
  end
end
