#
# LinkageStore is a class which acts as an interface to SQLite3
#
# If the cache hasn't changed, don't do extra processing in LinkageChecker.
# Instead, just fetch the data stored in the cache
#

require "os/mac/linkage_database"

class LinkageStore
  # Updates cached values in SQLite3 tables according to the type of data stored
  #
  # @param  [String] key
  # @param  [Hash] array_linkage_values
  # @param  [Hash] hash_linkage_values
  # @return [nil]
  def update!(key:,
    array_linkage_values: {
      system_dylibs: %w[], variable_dylibs: %w[], broken_dylibs: %w[],
      undeclared_deps: %w[], unnecessary_deps: %w[]
    },
    hash_linkage_values: {
      brewed_dylibs: {}, reverse_links: {}
    })
    array_linkage_values.each do |type, table_values|
      insert_path_values(type, key, table_values)
    end

    hash_linkage_values.each do |type, values|
      values.each do |label, list|
        insert_hash_values(type, key, list, label)
      end
    end
  end

  # Fetches a subset of paths by looking up an array of keys
  #
  # @param  [String] type
  # @param  [Array[String]] keys
  # @return [Array[String]]
  def fetch_path_values!(type:, keys:)
    LinkageDatabase.db.execute(
      <<~SQL
        SELECT path FROM linkage
          WHERE type = '#{type}'
          AND name IN(#{LinkageDatabase.format_database_list(keys)});
      SQL
    ).flatten
  end

  # Fetches path and label values from a table name given an array of keys and
  # returns them in a hash format with the labels as keys to an array of paths
  #
  # @param  [String] type
  # @param  [Array[String]] keys
  # @return [Hash]
  def fetch_hash_values!(type:, keys:)
    hash = {}
    LinkageDatabase.db.execute(
      <<~SQL
        SELECT label, path FROM linkage
          WHERE type = '#{type}'
          AND name IN(#{LinkageDatabase.format_database_list(keys)});
      SQL
    ).each { |row| (hash[row[0]] ||=[]) << row[1] }
    hash
  end

  # Deletes rows given an array of keys. If the row's name
  # attribute contains a value in the array of keys, then that row is deleted
  #
  # @param  [Array[String]] keys
  # @return [nil]
  def flush_cache_for_keys!(keys:)
    LinkageDatabase.db.execute(
      <<~SQL
        DELETE FROM linkage
          WHERE name IN(#{LinkageDatabase.format_database_list(keys)});
      SQL
    )
  end

  private

  def insert_path_values(type, key, values)
    return if values.empty?

    LinkageDatabase.db.execute(
      <<~SQL
        INSERT INTO linkage (name, path, type)
          VALUES #{format_array_database_values(key, values, type)};
      SQL
    )
  end

  def insert_hash_values(type, key, values, label)
    return if values.empty?

    LinkageDatabase.db.execute(
      <<~SQL
        INSERT INTO linkage (name, path, type, label)
          VALUES #{format_hash_database_values(key, values, type, label)};
      SQL
    )
  end

  def format_array_database_values(key, values, type)
    values
      .map { |value| "('#{key}', '#{value}', '#{type}')" }
      .join(", ")
  end

  def format_hash_database_values(key, values, type, label)
    values
      .map { |value| "('#{key}', '#{value}', '#{type}', '#{label}')" }
      .join(", ")
  end
end
