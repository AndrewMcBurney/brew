require "os/mac/store/formula_store"

#
# The `FormulaChecker` class is an abstract base class used by the `brew uses`
# command to help find what dependencies or requirements a particular formula
# has
#
# @abstract
#
class FormulaChecker
  # Initializes new `FormulaChecker` class
  #
  # @param  [Formula] formula
  # @param  [Class] formulae
  # @param  [Array[String]] ignores
  # @param  [Array[String]] includes
  # @param  [Bool] cached
  # @return [nil]
  def initialize(formula, formulae, ignores, includes, cached)
    @formula  = formula
    @formulae = formulae
    @ignores  = ignores
    @includes = includes
    @cached   = cached

    @key      = formula.name
    @store    = FormulaStore.new(key, type)
  end

  # Finds package names using given `key`
  #
  # @return [Array[String]]
  def check_uses!
    return cached_formulae if cached
    store.flush_cache!
    store.update!(values: uses)
    uses
  end

  # Fetches cached values from the persistent formula store
  #
  # @return [Array[String]]
  def cached_formulae
    @cached_formulae ||= store.fetch
  end

  # The type of the checker. Can be `recursive` or `non_recursive`. Must be
  # implemented by concretions
  #
  # @abstract
  # @raise  [NotImplementedError]
  # @return [String]
  def type
    raise NotImplementedError
  end

  # Returns an array of dependencies and requirements for a given formula. Must
  # be implemented by concretions
  #
  # @abstract
  # @param  [Formula] f
  # @raise  [NotImplementedError]
  # @return [Array, Array]
  def dependencies_and_requirements(_f)
    raise NotImplementedError
  end

  private

  # @formula is the Formula class being checked for dependencies
  #
  # @return [Formula]
  attr_reader :formula

  # @formulae is a class for TODO:
  #
  # @return [Formulae]
  attr_reader :formulae

  # @ignores is an array of TODO
  #
  # @return [Array]
  attr_reader :ignores

  # @includes is an array of TODO
  #
  # @return [Array]
  attr_reader :includes

  # @cached returns true if data returned in `check_uses!` is cached.
  #
  # @return [Bool]
  attr_reader :cached

  # @key is the formula name
  #
  # @return [String]
  attr_reader :key

  # @store is the persistent store mechanism which updates the cache
  #
  # @return [FormulaStore]
  attr_reader :store

  # Finds the formula the particular `formula` uses
  #
  # @raise  [FormulaUnavailableError]
  # @return [Array[String]]
  def uses
    @uses ||= begin
      formulae.select do |f|
        begin
          deps, reqs = dependencies_and_requirements(f)
          next true if deps.any? { |dep| formula_name_matches_dep?(dep) }
          reqs.any? { |req| req.name == key }
        rescue FormulaUnavailableError
          # Silently ignore this case as we don't care about things used in
          # taps that aren't currently tapped.
          next
        end
      end.map(&:full_name)
    end
  end

  # Returns `true` if the formula name matches the dependency
  #
  # @return [Bool]
  def formula_name_matches_dep?(dep)
    dep.to_formula.full_name == formula.full_name
  rescue
    dep.name == key
  end
end
