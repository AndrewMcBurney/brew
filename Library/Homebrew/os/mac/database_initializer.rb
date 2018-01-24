require "os/mac/linkage_database"

#
# DatabaseInitializer initializes the database by creating the linkage table if
# it does not exist
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
