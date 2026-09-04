# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe "engine install migrations" do
  self.use_transactional_tests = false

  it "creates annotation tables on a fresh sqlite database", :aggregate_failures do
    previous_config = ActiveRecord::Base.connection_db_config

    Dir.mktmpdir do |directory|
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: File.join(directory, "install.sqlite3")
      )
      EngineSchema.migrate_engine!

      connection = ActiveRecord::Base.connection
      expect(connection.table_exists?(:annotation_reviews)).to be(true)
      expect(connection.table_exists?(:annotation_spans)).to be(true)

      json_column = connection.columns(:annotation_reviews).find { |column| column.name == "context_json" }
      expect(json_column.sql_type).to match(/json/i)
    end
  ensure
    ActiveRecord::Base.establish_connection(previous_config)
    EngineSchema.load!
  end
end
