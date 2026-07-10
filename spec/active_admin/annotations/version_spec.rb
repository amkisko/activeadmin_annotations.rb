# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations do
  it "defines a semver version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
