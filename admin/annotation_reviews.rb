# frozen_string_literal: true

ActiveAdmin.register ActiveAdmin::Annotations::Review, as: "annotation_reviews" do
  menu priority: 3,
    label: "Review",
    if: proc { ActiveAdmin::Annotations.review_menu_visible.call(current_user) },
    menu_name: :auxiliary

  controller do
    def scoped_collection
      annotation_counts = ActiveAdmin::Annotations::Annotation
        .where("annotation_spans.annotation_review_id = annotation_reviews.id")
        .select("COUNT(*)")
      super.select("annotation_reviews.*", "(#{annotation_counts.to_sql}) AS annotations_count")
    end
  end

  actions :index, :show, :create, :update

  permit_params :review_status, :notes

  filter :subject_type, as: :select
  filter :subject_id
  filter :reviewer_id, label: "Reviewer"
  filter :review_status, as: :select, collection: ActiveAdmin::Annotations::Review::REVIEW_STATUSES
  filter :context_digest
  filter :created_at

  scope :all, default: true
  scope :pending
  scope :reviewed
  scope :escalated
  scope :needs_follow_up

  index do
    selectable_column
    id_column
    column :subject_type
    column :subject_id
    column :reviewer
    column :review_status
    column("Annotations") { |review| review.annotations_count }
    column :context_digest
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :subject do |review|
        label = "#{review.subject_type} ##{review.subject_id}"
        subject = review.subject
        if subject.present?
          auto_link(subject, label)
        else
          label
        end
      end
      row :reviewer
      row :review_status
      row :notes
      row :context_digest
      if ActiveAdmin::Annotations::ContentRevision.enabled_for?(resource.subject)
        row :content_revision_version
      end
      row("Context stale?") { |review| review.context_stale? ? "yes" : "no" }
      row :created_at
      row :updated_at
    end

    panel "Context" do
      pre JSON.pretty_generate(resource.context_json)
    end

    panel "Annotations" do
      if resource.annotations.any?
        table_for(resource.annotations.order(:created_at)) do
          column :field_name
          column :selected_text
          column :comment
          column :category
          if ActiveAdmin::Annotations::ContentRevision.enabled_for?(resource.subject)
            column :content_revision_version
          end
          column :start_offset
          column :end_offset
        end
      else
        para "No annotations yet."
      end
    end
  end

  collection_action :export_jsonl, method: :get do
    exporter = ActiveAdmin::Annotations::Exporter.new(reviews: collection)
    filename = "annotation-reviews-#{Time.current.strftime("%Y%m%d%H%M%S")}.jsonl"
    headers["Content-Type"] = "application/jsonl"
    headers["Content-Disposition"] = %(attachment; filename="#{filename}")
    self.response_body = Enumerator.new do |yielder|
      exporter.each_jsonl_row do |row|
        yielder << "#{JSON.generate(row)}\n"
      end
    end
  end

  action_item :export_jsonl, only: :index do
    link_to "Export JSONL", export_jsonl_admin_annotation_reviews_path(request.query_parameters), class: "action-item-button"
  end
end
