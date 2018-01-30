require "os/mac/database/database"

#
# Database schema:
#
# CREATE TABLE IF NOT EXISTS formula (
#   id         INTEGER PRIMARY KEY AUTOINCREMENT,
#   name       TEXT NOT NULL,
#   type       TEXT NOT NULL CHECK (type IN ('recursive', 'non_recursive')),
#   dependency TEXT NOT NULL,
#   UNIQUE(name, dependency) ON CONFLICT IGNORE
# );
#
class FormulaDatabase < Database
  # Initializes new `LinkageDatabase` class
  #
  # @return [nil]
  def initialize
    super("formula")
  end

  # Creates database table for SQLite3 linkage caching mechanism, if the
  # table 'linkage' does not exist
  #
  # @return [nil]
  def create_tables
    db.execute <<~SQL
      CREATE TABLE IF NOT EXISTS formula (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT NOT NULL,
        type       TEXT NOT NULL CHECK (type IN ('recursive', 'non_recursive')),
        dependency TEXT NOT NULL,
        UNIQUE(name, type, dependency) ON CONFLICT IGNORE
      );
    SQL
  end
end
