# frozen_string_literal: true

module ActiveAdmin
  module Annotations
    class Engine < ::Rails::Engine
      engine_name "activeadmin_annotations"

      isolate_namespace ActiveAdmin::Annotations

      config.generators do |generator|
        generator.test_framework :rspec
      end

      initializer "activeadmin_annotations.active_admin", after: :load_config_initializers do
        next unless defined?(ActiveAdmin) && ActiveAdmin.respond_to?(:application)

        ActiveAdmin.application.load_paths << ActiveAdmin::Annotations::Engine.root.join("admin").to_s
      end

      initializer "activeadmin_annotations.importmap", after: :load_config_initializers do
        next unless Rails.application.respond_to?(:importmap)

        pin_controller = proc do |importmap|
          importmap.pin "controllers/activeadmin_annotations/annotator_controller",
            to: "activeadmin_annotations/annotator_controller.js"
          importmap.pin "controllers/activeadmin_annotations/clipboard_controller",
            to: "activeadmin_annotations/clipboard_controller.js"
        end

        Rails.application.importmap.draw(&pin_controller)
        ActiveAdmin.importmap.draw(&pin_controller) if defined?(ActiveAdmin)
      end

      initializer "activeadmin_annotations.assets" do |app|
        assets_path = root.join("app/assets")
        app.config.importmap.cache_sweepers << assets_path.join("controllers") if app.config.respond_to?(:importmap)

        next unless app.config.respond_to?(:assets)

        app.config.assets.precompile << "activeadmin_annotations.css"
      end

      initializer "activeadmin_annotations.view_helpers" do
        ActiveSupport.on_load(:action_view) do
          include ActiveAdmin::Annotations::PanelHelper
        end
      end
    end
  end
end
