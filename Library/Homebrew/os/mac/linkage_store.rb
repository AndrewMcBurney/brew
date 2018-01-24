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
    db.transaction do
      db[key] = {
        path_values: path_values,
        brewed_dylibs: format_hash_values(hash_values[:brewed_dylibs]),
        reverse_links: format_hash_values(hash_values[:reverse_links]),
      }
    end
  end

  # Fetches a subset of paths by looking up an array of keys
  #
  # @param  [String] type
  # @return [Array[String]]
  def fetch_path_values!(type:)
    db.transaction { db[key][:path_values][type.to_sym] }
  end

  # Fetches path and label values from a table name given an array of keys and
  # returns them in a hash format with the labels as keys to an array of paths
  #
  # @param  [String] type
  # @return [Hash]
  def fetch_hash_values!(type:)
    data db.transaction { db[key][type.to_sym] }
    data == nil ? {} : data.reduce({}, :update)
  end

  # Flushes the cache for the given 'key' name
  #
  # @return [nil]
  def flush_cache!
    db.transaction { db.delete(key) }
  end

  private

  # `pstore` throws an error if the hash is empty, or if the hash contains Set
  # values
  #
  # Error: can't dump hash with default proc
  #
  # @param  [Hash] hash
  # @return [Hash]
  def format_hash_values(hash)
    hash.empty? ? nil : hash.map { |k, v| { k => v.to_a } }
  end
end
