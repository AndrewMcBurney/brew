require "os/mac/store/store"
require "os/mac/database/linkage_database"
require "os/mac/database/helpers/linkage_database_types"

#
# `LinkageStore` is a class which acts as an interface to a persistent storage
# mechanism
#
# If the cache hasn't changed, don't do extra processing in `LinkageChecker`.
# Instead, just fetch the data stored in the cache
#
class LinkageStore < Store
  include LinkageDatabaseTypes

  # @key is the keg name for the `LinkageStore` class
  #
  # @return [String]
  attr_reader :key

  # Initializes new `LinkageStore` class
  #
  # @param  [String] keg_name
  # @return [nil]
  def initialize(keg_name)
    @key = keg_name
    super(LinkageDatabase.new)
  end

  # Updates cached values in the persistent store according to the type of data
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

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @param  [String] type
  # @return [Any]
  def fetch(type:)
    if HASH_LINKAGE_TYPES.include?(type)
      fetch_hash_values(type: type)
    else
      fetch_path_values(type: type)
    end
  end

  # A condition for where to flush the cache (i.e., where to delete rows)
  #
  # @return [String]
  def flush_condition
    "name = '#{key}'"
  end

  private

  # Fetches a subset of paths where the name = `key`
  #
  # @param  [String] type
  # @return [Array[String]]
  def fetch_path_values(type:)
    db.execute(
      <<~SQL
        SELECT path FROM linkage
          WHERE type = '#{type}'
          AND name = '#{key}';
      SQL
    ).flatten
  end

  # Fetches a subset of paths and labels where the name = `key`. Formats said
  # paths/labels into `key => [value]` syntax expected by `LinkageChecker`
  #
  # @param  [String] type
  # @return [Hash]
  def fetch_hash_values(type:)
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

  # Inserts values into the persistent store
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
