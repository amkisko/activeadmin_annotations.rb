# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::Exporter do
  it "exports one jsonl row per annotation", :aggregate_failures do
    review = create(:annotation_review)
    annotation = create(:annotation, annotation_review: review)

    row = JSON.parse(described_class.new(reviews: [review]).to_jsonl.lines.first)

    expect(row.fetch("review_id")).to eq(review.id)
    expect(row.fetch("annotation_id")).to eq(annotation.id)
    expect(row.fetch("annotation").fetch("comment")).to eq(annotation.comment)
    expect(row.fetch("context").fetch("output").fetch("headline")).to eq("Week")
  end

  it "avoids per-review annotation queries when annotations are preloaded", :aggregate_failures do
    reviews = create_list(:annotation_review, 2)
    reviews.each { |review| create(:annotation, annotation_review: review) }
    relation = ActiveAdmin::Annotations::Review.where(id: reviews.map(&:id))

    count_annotation_span_queries = lambda do |reviews_for_export|
      queries = []
      ActiveSupport::Notifications.subscribed(
        lambda { |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          queries << event.payload[:sql] if event.payload[:sql].to_s.include?("annotation_spans")
        },
        "sql.active_record"
      ) do
        described_class.new(reviews: reviews_for_export).to_jsonl
      end
      queries.size
    end

    expect(count_annotation_span_queries.call(relation.to_a)).to eq(2)
    expect(count_annotation_span_queries.call(relation.includes(:annotations).to_a)).to eq(0)
  end

  it "exports rows from a review relation", :aggregate_failures do
    review = create(:annotation_review)
    annotation = create(:annotation, annotation_review: review)

    output = described_class.new(reviews: ActiveAdmin::Annotations::Review.where(id: review.id)).to_jsonl
    row = JSON.parse(output.lines.first)

    expect(row.fetch("review_id")).to eq(review.id)
    expect(row.fetch("annotation_id")).to eq(annotation.id)
  end

  it "preloads annotations once per batch when exporting a relation" do
    reviews = create_list(:annotation_review, 2)
    reviews.each { |review| create(:annotation, annotation_review: review) }
    relation = ActiveAdmin::Annotations::Review.where(id: reviews.map(&:id))

    queries = []
    ActiveSupport::Notifications.subscribed(
      lambda { |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        queries << event.payload[:sql] if event.payload[:sql].to_s.include?("annotation_spans")
      },
      "sql.active_record"
    ) do
      described_class.new(reviews: relation).to_jsonl
    end

    expect(queries.size).to eq(1)
  end

  it "preloads subjects once per batch when exporting a relation" do
    reviews = create_list(:annotation_review, 2)
    reviews.each { |review| create(:annotation, annotation_review: review) }
    relation = ActiveAdmin::Annotations::Review.where(id: reviews.map(&:id))

    queries = []
    ActiveSupport::Notifications.subscribed(
      lambda { |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        queries << event.payload[:sql] if event.payload[:sql].to_s.match?(/FROM ["']?documents["']?/i)
      },
      "sql.active_record"
    ) do
      described_class.new(reviews: relation).to_jsonl
    end

    expect(queries.size).to eq(1)
  end
end
