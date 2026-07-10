# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::ContentRevision do
  around do |example|
    original_strategy = ActiveAdmin::Annotations.content_revision_strategy
    original_current = ActiveAdmin::Annotations.current_content_revision_version
    original_subject = ActiveAdmin::Annotations.content_subject_for_revision
    example.run
  ensure
    ActiveAdmin::Annotations.content_revision_strategy = original_strategy
    ActiveAdmin::Annotations.current_content_revision_version = original_current
    ActiveAdmin::Annotations.content_subject_for_revision = original_subject
  end

  it "is disabled for subjects without revisions" do
    document = create(:document)
    ActiveAdmin::Annotations.content_revision_strategy = :auto

    expect(described_class.enabled_for?(document)).to be(false)
    expect(described_class.current_version_for(document)).to eq(0)
    expect(described_class.content_subject_for(document, 0)).to eq(document)
  end

  it "is disabled when strategy is none" do
    document = create(:document)
    ActiveAdmin::Annotations.content_revision_strategy = :none

    expect(described_class.enabled_for?(document)).to be(false)
  end

  it "supports custom revision resolvers without active_version", :aggregate_failures do
    ActiveAdmin::Annotations.content_revision_strategy = :auto
    ActiveAdmin::Annotations.current_content_revision_version = ->(_subject) { 3 }
    ActiveAdmin::Annotations.content_subject_for_revision = lambda do |subject, version|
      subject.dup.tap { |record| record.body = "Snapshot #{version}" }
    end

    document = create(:document, body: "Live")

    expect(described_class.enabled_for?(document)).to be(true)
    expect(described_class.current_version_for(document)).to eq(3)
    expect(described_class.content_subject_for(document, 2).body).to eq("Snapshot 2")
  end
end
