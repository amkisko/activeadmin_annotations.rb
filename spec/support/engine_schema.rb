# frozen_string_literal: true

module EngineSchema
  module_function

  def load!
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Migration.verbose = false
    load DUMMY_ROOT.join("db", "schema.rb").to_s
    migrate_engine!
  end

  def migrate_engine!
    ActiveRecord::Migration.verbose = false
    paths = [ActiveAdmin::Annotations::Engine.root.join("db/migrate").to_s]
    ActiveRecord::MigrationContext.new(paths, schema_migration).migrate
  end

  def schema_migration
    pool = ActiveRecord::Base.connection_pool
    return pool.schema_migration if pool.respond_to?(:schema_migration)

    ActiveRecord::Base.connection.schema_migration
  end
end
