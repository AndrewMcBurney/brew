#
# LinkageDatabase is a module to interface with the SQLite3 database
#
# Database schema:
#
# CREATE TABLE IF NOT EXISTS linkage (
#   id INTEGER PRIMARY KEY AUTOINCREMENT,
#   name TEXT NOT NULL,
#   path TEXT NOT NULL,
#   type TEXT NOT NULL CHECK (type IN (#{types})),
#   label TEXT CHECK (label IS NULL OR (type IN (#{hash_types}))),
#   UNIQUE(name, path, type, label) ON CONFLICT IGNORE
# );
#
module LinkageDatabase
  # Install and require SQLite3 ruby gem for caching purposes
  Homebrew.install_gem_setup_path! "sqlite3"
  require "sqlite3"

  # GENERALIZED_LINKAGE_TYPES are rows which have a 'label' attribute which is
  # NULL. There is a constraint check to ensure these types do not have a label:
  #
  #   - CHECK (label IS NULL OR (type IN (#{hash_types})))
  GENERALIZED_TYPES = %w[
    system_dylibs variable_dylibs broken_dylibs undeclared_deps unnecessary_deps
  ].freeze

  # HASH_LINKAGE_TYPES are rows which have a 'label' attribute which is NOT
  # NULL. There is a constraint check to ensure these types have a label:
  #
  #   - CHECK (label IS NULL OR (type IN (#{hash_types})))
  HASH_LINKAGE_TYPES = %w[
    brewed_dylibs reverse_links
  ].freeze

  #
  # LinkageDatabase::DatabaseInitializer initializes the database by creating
  # the linkage table if it does not exist
  #
  class DatabaseInitializer
    include LinkageDatabase

    # Creates database table for SQLite3 linkage caching mechanism, if the
    # table 'linkage' does not exist
    #
    # @return [nil]
    def create_linkage_table
      db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS linkage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          type TEXT NOT NULL CHECK (type IN (#{all_types})),
          label TEXT CHECK (label IS NULL OR (type IN (#{hash_types}))),
          UNIQUE(name, path, type, label) ON CONFLICT IGNORE
        );
      SQL
    end

    private

    def all_types
      format_database_list(GENERALIZED_TYPES + HASH_LINKAGE_TYPES)
    end

    def hash_types
      format_database_list(HASH_LINKAGE_TYPES)
    end

    # Takes in an array of strings, and formats them into a SQL list string
    #
    # @param  [Array[String]] list
    # @return [String]
    def format_database_list(list)
      list
        .map { |value| "'#{value}'" }
        .join(", ")
    end
  end

  # Expose linkage database through LinkageDatabase module
  #
  # @return [SQLite3::Database] db
  def db
    @db ||= SQLite3::Database.new "#{HOMEBREW_CACHE}/linkage.db"
  end

  begin
    DatabaseInitializer.new.create_linkage_table
  rescue SQLite3::CantOpenException => e
    puts "Problem opening database file. Error: #{e}"
  rescue SQLite3::SQLException => e
    puts "Problem creating database tables for linkage database. Error: #{e}"
  end
end
