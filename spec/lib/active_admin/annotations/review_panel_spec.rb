# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::ReviewPanel do
  let(:reviewer) { create(:user) }
  let(:document) { create(:document, body: "Summary body") }
  let(:view_context) do
    Class.new do
      attr_accessor :panel_calls

      def initialize
        @panel_calls = []
      end

      def helpers
        self
      end

      def activeadmin_annotations_panel(**options)
        panel_calls << options
        "panel"
      end
    end.new
  end

  it "previews a review without persisting and renders the panel", :aggregate_failures do
    result = nil

    expect do
      result = described_class.render(
        subject: document,
        reviewer: reviewer,
        field: :body,
        view_context: view_context,
        context_builder: ->(content_subject) { {body: content_subject.body} },
        content_builder: ->(content_subject) { content_subject.body }
      )
    end.not_to change(ActiveAdmin::Annotations::Review, :count)

    expect(result).to eq("panel")
    expect(view_context.panel_calls.length).to eq(1)

    panel_options = view_context.panel_calls.first
    expect(panel_options[:subject]).to eq(document)
    expect(panel_options[:field]).to eq("body")
    expect(panel_options[:review]).not_to be_persisted
    expect(panel_options[:review].reviewer).to eq(reviewer)
    expect(panel_options[:content]).to eq("Summary body")
    expect(panel_options[:content_revision_enabled]).to be(false)
    expect(panel_options[:readonly]).to be(false)
  end

  it "filters annotations to the browsed revision when viewing a pinned version", :aggregate_failures do
    ActiveAdmin::Annotations.content_revision_strategy = :auto
    ActiveAdmin::Annotations.current_content_revision_version = ->(subject) { subject.revision_version }

    document.update!(revision_version: 1)

    review = create(
      :annotation_review,
      subject: document,
      reviewer: reviewer,
      content_revision_version: 1
    )
    create(
      :annotation,
      annotation_review: review,
      field_name: "body",
      content_revision_version: 0,
      selected_text: "old text"
    )
    matching_annotation = create(
      :annotation,
      annotation_review: review,
      field_name: "body",
      content_revision_version: 1,
      selected_text: "new text"
    )

    described_class.render(
      subject: document,
      reviewer: reviewer,
      field: :body,
      view_context: view_context,
      viewing_content_revision_version: 1,
      context_builder: ->(content_subject) { {body: content_subject.body} },
      content_builder: ->(content_subject) { content_subject.body }
    )

    panel_options = view_context.panel_calls.first
    expect(panel_options[:annotations].map(&:id)).to eq([matching_annotation.id])
    expect(panel_options[:advance_review_url]).to be_nil
    expect(panel_options[:readonly]).to be(false)
  end

  it "marks the panel read-only when browsing another version", :aggregate_failures do
    ActiveAdmin::Annotations.content_revision_strategy = :auto
    ActiveAdmin::Annotations.current_content_revision_version = ->(subject) { subject.revision_version }

    create(:annotation_review, subject: document, reviewer: reviewer, content_revision_version: 1)
    document.update!(revision_version: 1)

    described_class.render(
      subject: document,
      reviewer: reviewer,
      field: :body,
      view_context: view_context,
      viewing_content_revision_version: 0,
      context_builder: ->(content_subject) { {body: content_subject.body} },
      content_builder: ->(content_subject) { content_subject.body }
    )

    panel_options = view_context.panel_calls.first
    expect(panel_options[:readonly]).to be(true)
    expect(panel_options[:content_revision_version]).to eq(0)
  end
end
