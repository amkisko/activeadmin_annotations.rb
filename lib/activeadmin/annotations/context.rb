# frozen_string_literal: true

require "digest"

module ActiveAdmin::Annotations
  module Context
    def self.digest_for(context)
      Digest::SHA256.hexdigest(context.to_json)
    end
  end
end
