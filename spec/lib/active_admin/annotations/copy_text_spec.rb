# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::CopyText do
  let(:review) { create(:annotation_review, notes: "Check evidence bands.") }
  let(:annotation) do
    create(
      :annotation,
      annotation_review: review,
      selected_text: "Shipped export",
      comment: "Claim is stronger than the evidence bands support.",
      category: "overconfident_claim",
      start_offset: 12,
      end_offset: 27,
      context_paths_json: ["output.summary_markdown"]
    )
  end

  it "includes annotation, review, and context details", :aggregate_failures do
    text = described_class.for(annotation)

    expect(text).to include("Shipped export")
    expect(text).to include("Claim is stronger than the evidence bands support.")
    expect(text).to include("Overconfident claim")
    expect(text).to include("12")
    expect(text).to include("27")
    expect(text).to include("output.summary_markdown")
    expect(text).to include("Check evidence bands.")
    expect(text).to include('"headline": "Week"')
    expect(text).to include(annotation.id)
    expect(text).to include(review.id)
  end

  it "prepends configured copy instructions" do
    ActiveAdmin::Annotations.copy_instructions = "Use these spans to grade summary quality."

    text = described_class.for(annotation)

    expect(text).to start_with("Use these spans to grade summary quality.")
  end

  it "supports callable copy instructions" do
    ActiveAdmin::Annotations.copy_instructions = lambda do |current_annotation, current_review|
      "Annotation #{current_annotation.id} for review #{current_review.id}"
    end

    text = described_class.for(annotation)

    expect(text).to start_with("Annotation #{annotation.id} for review #{review.id}")
  end
end
