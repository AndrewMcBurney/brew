require "os/mac/store/store"
require "os/mac/database/formula_database"

#
# `FormulaStore` is a class which acts as an interface to a persistent storage
# mechanism
#
# If the cache hasn't changed, don't do extra processing for `brew uses`.
# Instead, just fetch the data stored in the cache
#
class FormulaStore < Store
  # Initializes new `FormulaStore` class
  #
  # @param  [String] key
  # @param  [String] type
  # @return [nil]
  def initialize(key, type)
    @key  = key
    @type = type
    super(FormulaDatabase.new)
  end

  # Updates cached values in the persistent store
  #
  # @param  [Array[String]] values
  # @return [nil]
  def update!(values:)
    return if values.empty?

    db.execute(
      <<~SQL
        INSERT INTO formula (name, type, dependency)
          VALUES #{format_database_values(values)};
      SQL
    )
  end

  # Fetches cached values in persistent storage according to the type of data
  # stored
  #
  # @return [Array[String]]
  def fetch
    db.execute(
      <<~SQL
        SELECT dependency FROM formula
          WHERE type = '#{type}' AND
          name = '#{key}';
      SQL
    ).flatten
  end

  # A condition for where to flush the cache (i.e., where to delete rows)
  #
  # @return [String]
  def flush_condition
    "type = '#{type}' AND name = '#{key}'"
  end

  private

  # @key is the keg name for the `FormulaStore` class
  #
  # @return [String]
  attr_reader :key

  # @type is the
  #
  # @return [String]
  attr_reader :type

  # Formats values for insertion into database, and returns a comma-separated
  # string of values
  #
  # @param  [Array[String]] values
  # @return [String]
  def format_database_values(values)
    values
      .map { |value| "('#{key}', '#{type}', '#{value}')" }
      .join(", ")
  end
end
