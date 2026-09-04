# frozen_string_literal: true

module ActiveAdmin::Annotations
  class PanelHtml
    def self.prepare(content)
      return "".html_safe if content.nil?

      html = content.to_s
      prepared = if content.respond_to?(:html_safe?) && content.html_safe?
        sanitizer.sanitize(html)
      else
        ERB::Util.html_escape(html)
      end
      prepared.html_safe
    end

    def self.sanitizer
      Rails::HTML::Sanitizer.safe_list_sanitizer.new
    end
  end
end
