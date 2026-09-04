# frozen_string_literal: true

require "rails_helper"

RSpec.describe "annotation spans", type: :request do
  let(:reviewer) { create(:user) }
  let(:other_reviewer) { create(:user) }
  let(:document) { create(:document) }
  let(:review) { create(:annotation_review, subject: document, reviewer: reviewer) }

  def span_payload(overrides = {})
    {
      field_name: "body",
      selected_text: "Summary",
      start_offset: 0,
      end_offset: 7,
      comment: "Needs a source.",
      category: "overconfident_claim"
    }.merge(overrides)
  end

  it "creates a span on an existing review and returns the review id", :aggregate_failures do
    sign_in(reviewer)

    post admin_annotation_spans_path(format: :json),
      params: {annotation: span_payload(annotation_review_id: review.id)},
      as: :json

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body.fetch("annotation_review_id")).to eq(review.id)
    expect(ActiveAdmin::Annotations::Annotation.where(annotation_review: review).count).to eq(1)
  end

  it "creates a review on first span save when no review id is sent", :aggregate_failures do
    sign_in(reviewer)

    expect do
      post admin_annotation_spans_path(format: :json),
        params: {
          annotation: span_payload(
            subject_type: "Document",
            subject_id: document.id,
            context_json: {"body" => document.body},
            context_digest: "digest-1",
            displayed_content_revision_version: 0
          )
        },
        as: :json
    end.to change(ActiveAdmin::Annotations::Review, :count).by(1)
      .and change(ActiveAdmin::Annotations::Annotation, :count).by(1)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body.fetch("annotation_review_id")).to be_present
  end

  it "rejects create when the displayed version does not match the pin", :aggregate_failures do
    sign_in(reviewer)
    review.update!(content_revision_version: 1)

    expect do
      post admin_annotation_spans_path(format: :json),
        params: {
          annotation: span_payload(
            annotation_review_id: review.id,
            displayed_content_revision_version: 0
          )
        },
        as: :json
    end.not_to change(ActiveAdmin::Annotations::Annotation, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body).fetch("errors")).to include("This version is read-only.")
  end

  it "updates an owned span", :aggregate_failures do
    sign_in(reviewer)
    annotation = create(:annotation, annotation_review: review, field_name: "body")

    patch admin_annotation_span_path(annotation, format: :json),
      params: {annotation: {comment: "Revised comment."}},
      as: :json

    expect(response).to have_http_status(:ok)
    expect(annotation.reload.comment).to eq("Revised comment.")
  end

  it "deletes an owned span" do
    sign_in(reviewer)
    annotation = create(:annotation, annotation_review: review, field_name: "body")

    delete admin_annotation_span_path(annotation, format: :json)

    expect(response).to have_http_status(:no_content)
    expect(ActiveAdmin::Annotations::Annotation.where(id: annotation.id)).to be_empty
  end

  it "returns copy text for an owned span" do
    sign_in(reviewer)
    annotation = create(:annotation, annotation_review: review)

    get copy_text_admin_annotation_span_path(annotation)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(annotation.comment)
    expect(response.body).not_to include("Reviewer ID:")
  end

  it "forbids mutating another reviewer's span", :aggregate_failures do
    sign_in(other_reviewer)
    annotation = create(:annotation, annotation_review: review, field_name: "body")

    patch admin_annotation_span_path(annotation, format: :json),
      params: {annotation: {comment: "Hijack"}},
      as: :json

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body).fetch("errors")).to include("Annotation access denied")
    expect(annotation.reload.comment).not_to eq("Hijack")
  end

  it "forbids showing another reviewer's span" do
    sign_in(other_reviewer)
    annotation = create(:annotation, annotation_review: review)

    get admin_annotation_span_path(annotation, format: :json)

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body).fetch("errors")).to include("Annotation access denied")
  end

  it "does not list another reviewer's spans" do
    sign_in(other_reviewer)
    annotation = create(:annotation, annotation_review: review)

    get admin_annotation_spans_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(annotation.id)
  end
end
