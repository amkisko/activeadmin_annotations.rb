# frozen_string_literal: true

ActiveRecord::Schema.define(version: 0) do
  create_table :users, id: :uuid, force: :cascade do |t|
    t.string :email
    t.timestamps
  end

  create_table :documents, id: :uuid, force: :cascade do |t|
    t.text :body
    t.integer :revision_version, null: false, default: 0
    t.timestamps
  end
end
