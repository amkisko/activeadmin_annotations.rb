# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::Annotations::PanelHelper do
  let(:helper) do
    Class.new do
      include ActiveAdmin::Annotations::PanelHelper

      attr_accessor :current_user, :last_render

      def render(**options)
        self.last_render = options
        ""
      end

      def capture(&block)
        block.call
      end
    end.new
  end

  let(:subject_record) { create(:document) }

  it "renders read-only content when reviewer is missing" do
    helper.current_user = nil

    helper.activeadmin_annotations_panel(
      subject: subject_record,
      field: :body,
      context: {title: "Doc"}
    ) { "annotated body" }

    expect(helper.last_render).to eq(
      partial: "active_admin/annotations/read_only_content",
      locals: {content: "annotated body"}
    )
  end

  it "does not persist a review when the reviewer is present" do
    helper.current_user = create(:user)

    expect do
      helper.activeadmin_annotations_panel(
        subject: subject_record,
        field: :body,
        context: {title: "Doc"}
      ) { "annotated body" }
    end.not_to change(ActiveAdmin::Annotations::Review, :count)
  end

  it "prepares ordinary content so tags are not HTML elements", :aggregate_failures do
    helper.current_user = nil

    helper.activeadmin_annotations_panel(
      subject: subject_record,
      field: :body,
      context: {title: "Doc"}
    ) { %(<script>alert(1)</script>hello) }

    fragment = Nokogiri::HTML.fragment(helper.last_render.fetch(:locals).fetch(:content))
    expect(fragment.css("script")).to be_empty
    expect(fragment.text).to include("hello")
  end

  it "keeps html-safe paragraphs and strips script from the panel locals", :aggregate_failures do
    helper.current_user = create(:user)

    helper.activeadmin_annotations_panel(
      subject: subject_record,
      field: :body,
      context: {title: "Doc"},
      content: %(<p>Reviewed body</p><script>alert(1)</script>).html_safe
    )

    fragment = Nokogiri::HTML.fragment(helper.last_render.fetch(:locals).fetch(:content))
    expect(fragment.css("script")).to be_empty
    expect(fragment.css("p").map(&:text)).to eq(["Reviewed body"])
  end
end
