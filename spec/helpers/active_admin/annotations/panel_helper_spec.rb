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
end
