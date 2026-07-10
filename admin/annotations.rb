# frozen_string_literal: true

ActiveAdmin.register ActiveAdmin::Annotations::Annotation, as: "annotation_spans" do
  menu false

  actions :index, :show, :create, :update, :destroy

  permit_params :annotation_review_id,
    :field_name,
    :selected_text,
    :start_offset,
    :end_offset,
    :comment,
    :category,
    :content_revision_version,
    context_paths_json: []

  filter :annotation_review
  filter :field_name
  filter :category
  filter :comment
  filter :created_at

  index do
    selectable_column
    id_column
    column :annotation_review
    column :field_name
    column :selected_text
    column :category
    column :created_at
    actions
  end

  member_action :copy_text, method: :get do
    render plain: ActiveAdmin::Annotations::CopyText.for(resource)
  end

  action_item :copy_details, only: :show do
    render partial: "active_admin/annotations/copy_details_action",
      locals: {copy_text_url: copy_text_admin_annotation_span_path(resource)}
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :annotation_review
      row :field_name
      row :selected_text
      row :start_offset
      row :end_offset
      row :comment
      row :category
      row :content_revision_version
      row :context_paths_json
      row :created_at
      row :updated_at
    end
  end

  controller do
    before_action :authorize_annotation_access!, only: %i[update destroy copy_text]

    def create
      review = authorize_review_for_create!
      return if performed?

      assign_content_revision_version_from_review(review)
      super do |success, failure|
        success.html { redirect_to request.referer || resource_path, notice: "Annotation saved." }
        success.json { render json: annotation_json(resource), status: :created }
        failure.html { redirect_to request.referer || admin_root_path, alert: resource.errors.full_messages.to_sentence }
        failure.json { render json: {errors: resource.errors.full_messages}, status: :unprocessable_entity }
      end
    end

    def update
      super do |success, failure|
        success.html { redirect_to request.referer || resource_path, notice: "Annotation updated." }
        success.json { render json: annotation_json(resource), status: :ok }
        failure.html { redirect_to request.referer || admin_root_path, alert: resource.errors.full_messages.to_sentence }
        failure.json { render json: {errors: resource.errors.full_messages}, status: :unprocessable_entity }
      end
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to request.referer || admin_root_path, notice: "Annotation deleted." }
        success.json { head :no_content }
        failure.html { redirect_to request.referer || admin_root_path, alert: resource.errors.full_messages.to_sentence }
        failure.json { render json: {errors: resource.errors.full_messages}, status: :unprocessable_entity }
      end
    end

    private

    def authorize_review_for_create!
      ActiveAdmin::Annotations::ReviewAccess.review_for_span_create!(
        review_id: params.dig(:annotation, :annotation_review_id),
        reviewer: current_annotation_reviewer
      )
    rescue ActiveAdmin::Annotations::ReviewAccess::Forbidden, ActiveAdmin::Annotations::ReviewAccess::NotFound
      respond_to_denied_review_access
      nil
    end

    def authorize_annotation_access!
      ActiveAdmin::Annotations::ReviewAccess.authorize_annotation!(
        annotation: resource,
        reviewer: current_annotation_reviewer
      )
    rescue ActiveAdmin::Annotations::ReviewAccess::Forbidden
      respond_to_denied_review_access
    end

    def current_annotation_reviewer
      return current_user if respond_to?(:current_user, true)

      nil
    end

    def respond_to_denied_review_access
      if request.format.json?
        render json: {errors: ["Review not found"]}, status: :forbidden
      else
        redirect_to request.referer || admin_root_path, alert: "Review not found."
      end
    end

    def assign_content_revision_version_from_review(review)
      params[:annotation][:content_revision_version] = review.content_revision_version
    end

    def annotation_json(annotation)
      {
        id: annotation.id,
        field_name: annotation.field_name,
        selected_text: annotation.selected_text,
        start_offset: annotation.start_offset,
        end_offset: annotation.end_offset,
        comment: annotation.comment,
        category: annotation.category
      }
    end
  end
end
