# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations do
  it "defines a semver version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "matches the gemspec version" do
    gemspec_path = File.expand_path("../../../activeadmin_annotations.gemspec", __dir__)
    gemspec = Gem::Specification.load(gemspec_path)

    expect(described_class::VERSION).to eq(gemspec.version.to_s)
  end
end
