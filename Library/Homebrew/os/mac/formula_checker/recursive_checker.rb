require "os/mac/formula_checker/formula_checker"

#
# Class with the single responsibility of performing work to find dependencies
# and requirements for a particular formula
#
class RecursiveChecker < FormulaChecker
  attr_reader :type

  # Initializes new `RecursiveChecker` class
  #
  # @param  [Formula] formula
  # @param  [Bool] recursive
  # @param  [Class] formulae
  # @param  [Array[String]] ignores
  # @param  [Array[String]] includes
  # @return [nil]
  def initialize(formula, formulae, ignores, includes, cached = true)
    @type = "recursive"
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
    f.recursive_dependencies do |dependent, dep|
      prune_dependencies!(dependent, dep)
    end
  end

  # Memoized paramater function which returns an array of requirements for a
  # given formula `f`
  #
  # @param  [Formula] f
  # @return [Array[Requirement]]
  def reqs(f)
    dep_formulae = dep_to_formulae(deps)

    reqs_by_formula = ([f] + dep_formulae).flat_map do |formula|
      formula.requirements.map { |req| [formula, req] }
    end

    hash[key] = reqs_by_formula.reject! do |dependent, req|
      if req.recommended?
        ignores.include?("recommended?") || dependent.build.without?(req)
      elsif req.optional?
        !includes.include?("optional?") && !dependent.build.with?(req)
      elsif req.build?
        !includes.include?("build?")
      end
    end.map(&:last)
  end

  # Checks the dependencies and requirements for a given formula
  #
  # @return [Array, Array]
  def prune_dependencies!(dependent, dep)
    if (dep.recommended? && (ignores.include?("recommended?")|| dependent.build.without?(dep))) ||
       (dep.optional? && (!includes.include?("optional?") && !dependent.build.with?(dep))) ||
       (dep.build? && !includes.include?("build?"))
      Dependency.prune
    end

    # If a tap isn't installed, we can't find the dependencies of one
    # its formulae, and an exception will be thrown if we try.
    Dependency.keep_but_prune_recursive_deps if dep.is_a?(TapDependency) && !dep.tap.installed?
  end

  # Converts dependencies to formulas
  #
  # @param  [Array]
  # @return [Array]
  def dep_to_formulae(deps)
    deps.flat_map do |dep|
      begin
        dep.to_formula
      rescue
        []
      end
    end
  end
end
