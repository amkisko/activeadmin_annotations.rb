# frozen_string_literal: true

class Document < ApplicationRecord
  def current_version
    revision_version
  end
end
