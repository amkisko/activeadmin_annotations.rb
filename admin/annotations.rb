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
    before_action :authorize_annotation_access!, only: %i[show update destroy copy_text]

    def scoped_collection
      return super unless action_name == "index"

      reviewer = current_annotation_reviewer
      return super.none if reviewer.blank?

      super.joins(:annotation_review).where(annotation_reviews: {reviewer_id: reviewer.id})
    end

    def create
      review = authorize_review_for_create!
      return if performed?

      stamp_span_from_review!(review)
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
      ActiveAdmin::Annotations::SpanCreate.review_for!(
        params: params,
        reviewer: current_annotation_reviewer
      )
    rescue ActiveAdmin::Annotations::SpanCreate::ReadOnly => error
      respond_to_span_error(error, status: :unprocessable_entity)
      nil
    rescue ActiveAdmin::Annotations::ReviewAccess::NotFound => error
      respond_to_span_error(error, status: :not_found)
      nil
    rescue ActiveAdmin::Annotations::ReviewAccess::Forbidden => error
      respond_to_span_error(error, status: :forbidden)
      nil
    end

    def authorize_annotation_access!
      ActiveAdmin::Annotations::ReviewAccess.authorize_annotation!(
        annotation: resource,
        reviewer: current_annotation_reviewer
      )
    rescue ActiveAdmin::Annotations::ReviewAccess::NotFound => error
      respond_to_span_error(error, status: :not_found)
    rescue ActiveAdmin::Annotations::ReviewAccess::Forbidden => error
      respond_to_span_error(error, status: :forbidden)
    end

    def current_annotation_reviewer
      return current_user if respond_to?(:current_user, true)

      nil
    end

    def respond_to_span_error(error, status:)
      if request.format.json?
        render json: {errors: [error.message]}, status: status
      else
        redirect_to request.referer || admin_root_path, alert: error.message
      end
    end

    def stamp_span_from_review!(review)
      annotation_params = params[:annotation] ||= ActionController::Parameters.new
      annotation_params[:annotation_review_id] = review.id
      annotation_params[:content_revision_version] = review.content_revision_version
    end

    def annotation_json(annotation)
      {
        id: annotation.id,
        annotation_review_id: annotation.annotation_review_id,
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
