#
# LinkageStore is a class which acts as an interface to a persistent storage
# mechanism
#
# If the cache hasn't changed, don't do extra processing in LinkageChecker.
# Instead, just fetch the data stored in the cache
#

require "os/mac/linkage_database"

class LinkageStore
  include LinkageDatabase

  attr_reader :key

  # Initializes new LinkageStore class
  #
  # @param  [String] keg_name
  # @return [nil]
  def initialize(keg_name)
    @key = keg_name
  end

  # Updates cached values in pstore according to the type of data stored
  #
  # @param  [Hash] path_values
  # @param  [Hash] hash_values
  # @return [nil]
  def update!(
    path_values: {
      system_dylibs: %w[], variable_dylibs: %w[], broken_dylibs: %w[],
      undeclared_deps: %w[], unnecessary_deps: %w[]
    },
    hash_values: {
      brewed_dylibs: {}, reverse_links: {}
    }
  )
    path_values.each { |type, list| insert_values(type, list) }

    hash_values.each do |type, values|
      values.each { |label, list| insert_values(type, list, label) }
    end
  end

  # Fetches a subset of paths where the name = `key`
  #
  # @param  [String] type
  # @return [Array[String]]
  def fetch_path_values!(type:)
    db.execute(
      <<~SQL
        SELECT path FROM linkage
          WHERE type = '#{type}'
          AND name = '#{key}';
      SQL
    ).flatten
  end

  # Fetches a subset of paths and labels where the name = `key`. Formats said
  # paths/labels into `key => [value]` syntax expected by LinkageChecker
  #
  # @param  [String] type
  # @return [Hash]
  def fetch_hash_values!(type:)
    hash = {}
    db.execute(
      <<~SQL
        SELECT label, path FROM linkage
          WHERE type = '#{type}'
          AND name = '#{key}';
      SQL
    ).each { |row| (hash[row[0]] ||= []) << row[1] }
    hash
  end

  # Deletes rows where the 'name' attribute matches the `key`
  #
  # @return [nil]
  def flush_cache!
    db.execute(
      <<~SQL
        DELETE FROM linkage
          WHERE name = '#{key}';
      SQL
    )
  end

  private

  # Inserts values into the database
  #
  # @param  [String]        type
  # @param  [Array[String]] values
  # @param  [String]        label
  # @return [nil]
  def insert_values(type, values, label = "NULL")
    return if values.empty?

    db.execute(
      <<~SQL
        INSERT INTO linkage (name, path, type, label)
          VALUES #{format_database_values(type, values, label)};
      SQL
    )
  end

  # Formats values for insertion into database, and returns a comma-separated
  # string of values
  #
  # @param  [String]        type
  # @param  [Array[String]] values
  # @param  [String]        label
  # @return [String]
  def format_database_values(type, values, label)
    label = "'#{label}'" unless label == "NULL"

    values
      .map { |value| "('#{key}', '#{value}', '#{type}', #{label})" }
      .join(", ")
  end
end
