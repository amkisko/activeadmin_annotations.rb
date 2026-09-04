# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::PanelHtml do
  def fragment_for(content)
    Nokogiri::HTML.fragment(described_class.prepare(content))
  end

  it "shows ordinary strings as text instead of HTML elements", :aggregate_failures do
    fragment = fragment_for(%(<script>alert(1)</script>hello))

    expect(fragment.css("script")).to be_empty
    expect(fragment.text).to include("hello")
  end

  it "keeps safe tags from html-safe host content and strips script", :aggregate_failures do
    fragment = fragment_for(%(<p>Hello</p><script>alert(1)</script>).html_safe)

    expect(fragment.css("script")).to be_empty
    expect(fragment.css("p").map(&:text)).to eq(["Hello"])
  end

  it "strips event handlers from html-safe images" do
    fragment = fragment_for(%(<img src="x" onerror="alert(1)">).html_safe)
    image = fragment.at_css("img")

    expect(image["onerror"]).to be_nil
  end
end
