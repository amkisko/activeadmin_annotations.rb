# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::Annotation do
  it "rejects an end offset before the start offset", :aggregate_failures do
    annotation = build(:annotation, start_offset: 10, end_offset: 4)

    expect(annotation).not_to be_valid
    expect(annotation.errors[:end_offset]).to be_present
  end
end
