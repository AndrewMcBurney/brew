require "os/mac/database/database"
require "os/mac/database/helpers/linkage_database_types"

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
class LinkageDatabase < Database
  include LinkageDatabaseTypes

  # Initializes new `LinkageDatabase` class
  #
  # @return [nil]
  def initialize
    super("linkage")
  end

  # Creates database table for SQLite3 linkage caching mechanism, if the
  # table 'linkage' does not exist
  #
  # @return [nil]
  def create_tables
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

  # Returns a string database value list of all 'general' and 'hash' types
  #
  # @return [String]
  def all_types
    format_database_list(GENERALIZED_TYPES + HASH_LINKAGE_TYPES)
  end

  # Returns a string database value list of all 'hash' types
  #
  # @return [String]
  def hash_types
    format_database_list(HASH_LINKAGE_TYPES)
  end
end
