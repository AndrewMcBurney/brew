require "os/mac/formula_checker/formula_checker"

#
# Class with the single responsibility of performing work to find dependencies
# and requirements for a particular formula
#
class NonRecursiveChecker < FormulaChecker
  attr_reader :type

  # Initializes new `NonRecursiveChecker` class
  #
  # @param  [Formula] formula
  # @param  [Class] formulae
  # @param  [Array[String]] ignores
  # @param  [Array[String]] includes
  # @param  [Bool] cached
  # @return [nil]
  def initialize(formula, formulae, ignores, includes, cached = true)
    @type = "non_recursive"
    super(formula, formulae, ignores, includes, cached)
  end

  # Returns an array of dependencies and requirements for a given formula
  #
  # @param  [Formula] f
  # @return [Array[Dependency], Array[Requirement]]
  def dependencies_and_requirements(f)
    [deps(f), reqs(f)]
  end

  private

  # Memoized parameter function which returns an array of dependencies for a
  # given formula `f`
  #
  # @param  [Formula] f
  # @return [Array[Dependency]]
  def deps(f)
    f.deps.reject do |dep|
      ignores.any? { |ignore| dep.send(ignore) } &&
        includes.none? { |include| dep.send(include) }
    end
  end

  # Memoized paramater function which returns an array of requirements for a
  # given formula `f`
  #
  # @param  [Formula] f
  # @return [Array[Requirement]]
  def reqs(f)
    f.requirements.reject do |req|
      ignores.any? { |ignore| req.send(ignore) } &&
        includes.none? { |include| req.send(include) }
    end
  end
end
