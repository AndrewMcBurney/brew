# TODO: remove this line of code in favor of vendored gem solution
Homebrew.install_gem_setup_path! "sqlite3"
require "sqlite3"

#
# `Database` is an abstract base class representing a database caching schema
# residing in the Homebrew cache
#
# It asks concretions to override the pure-virtual `create_tables` method, where
# a concrete class may specify the schema for the given database
#
# @abstract
#
class Database
  # Name of the database file located in <HOMEBREW_CACHE>/<name>.rb
  #
  # @return [String]
  attr_accessor :name

  # Creates a database in the Homebrew cache with the name passed in
  #
  # @param  [String] name
  # @raise  [SQLite3::CantOpenException]
  # @return [nil]
  def initialize(name)
    @name = name

    begin
      create_tables
    rescue SQLite3::CantOpenException => e
      puts "Problem opening database file. Error: #{e}"
    end
  end

  # Memoized `SQLite3` database object with on-disk database located in the
  # `HOMEBREW_CACHE`
  #
  # @return [SQLite3::Database] db
  def db
    @db ||= SQLite3::Database.new "#{HOMEBREW_CACHE}/#{name}.db"
  end

  # Abstract method overridden by concretion classes. Creates database tables for
  # the corresponding database schema
  #
  # @abstract
  # @return [nil]
  def create_tables
    raise NotImplementedError
  end

  protected

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
