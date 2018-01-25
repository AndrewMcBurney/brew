#
# `Store` is a class which acts as an interface to a persistent storage mechanism
#
# If the cache hasn't changed, don't do extra processing in Homebrew. Instead,
# just fetch the data stored in the cache
#
# @abstract
#
class Store
  # A class instance providing access to the `SQLite3` database object
  #
  # @return [SQLite3::Database]
  attr_reader :db

  # The name of the persistent data storage
  #
  # @return [String]
  attr_reader :name

  # Initializes new `Store` class
  #
  # @param  [Database] database
  # @return [nil]
  def initialize(database)
    @db   = database.db
    @name = database.name
  end

  # Updates cached values in persistent storage according to the type of data
  # stored
  #
  # @abstract
  # @param  [Hash] values
  # @return [nil]
  def update!(*)
    raise NotImplementedError
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @abstract
  # @param  [Hash] values
  # @return [Any]
  def fetch(*)
    raise NotImplementedError
  end

  # A condition to specify what rows to delete when flushing the cache. This
  # method should be overridden by concrete classes extending abstract
  # `Database` class
  #
  # @abstract
  # @return [String]
  def flush_condition
    raise NotImplementedError
  end

  # Deletes rows where the `flush_condition` holds
  #
  # @return [nil]
  def flush_cache!
    db.execute(
      <<~SQL
        DELETE FROM #{name}
          WHERE #{flush_condition};
      SQL
    )
  end
end
