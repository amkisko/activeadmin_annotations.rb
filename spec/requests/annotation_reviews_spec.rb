# frozen_string_literal: true

require "rails_helper"

RSpec.describe "annotation reviews", type: :request do
  let(:reviewer) { create(:user) }
  let(:review) { create(:annotation_review, reviewer: reviewer) }

  it "exports jsonl for reviews with annotations" do
    sign_in(reviewer)
    annotation = create(:annotation, annotation_review: review)

    get export_jsonl_admin_annotation_reviews_path

    expect(response).to have_http_status(:ok)
    row = JSON.parse(response.body.lines.first)
    expect(row.fetch("annotation_id")).to eq(annotation.id)
    expect(row.fetch("review_id")).to eq(review.id)
  end

  it "ignores metadata_json on update", :aggregate_failures do
    sign_in(reviewer)
    expect(review.context_stale?).to be(false)

    patch admin_annotation_review_path(review),
      params: {
        review: {
          notes: "Check sources.",
          metadata_json: {"context_stale" => true, "needs_follow_up" => true}
        }
      }

    review.reload
    expect(review.notes).to eq("Check sources.")
    expect(review.context_stale?).to be(false)
    expect(review.needs_follow_up?).to be(false)
  end
end
