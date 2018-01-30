#:  * `uses` [`--installed`] [`--recursive`] [`--include-build`] [`--include-optional`] [`--skip-recommended`] [`--devel`|`--HEAD`] <formulae>:
#:    Show the formulae that specify <formulae> as a dependency. When given
#:    multiple formula arguments, show the intersection of formulae that use
#:    <formulae>.
#:
#:    Use `--recursive` to resolve more than one level of dependencies.
#:
#:    Use `--rebuild` to flush cache for formulae passed in
#:
#:    If `--installed` is passed, only list installed formulae.
#:
#:    By default, `uses` shows all formulae that specify <formulae> as a required
#:    or recommended dependency. To include the `:build` type dependencies, pass
#:    `--include-build`. Similarly, pass `--include-optional` to include `:optional`
#:    dependencies. To skip `:recommended` type dependencies, pass `--skip-recommended`.
#:
#:    By default, `uses` shows usages of <formulae> by stable builds. To find
#:    cases where <formulae> is used by development or HEAD build, pass
#:    `--devel` or `--HEAD`.

require "formula"
require "os/mac/formula_checker/recursive_checker"
require "os/mac/formula_checker/non_recursive_checker"

# `brew uses foo bar` returns formulae that use both foo and bar
# If you want the union, run the command twice and concatenate the results.
# The intersection is harder to achieve with shell tools.

module Homebrew
  module_function

  def uses
    raise FormulaUnspecifiedError if ARGV.named.empty?

    used_formulae_missing = false

    used_formulae = begin
      ARGV.formulae
    rescue FormulaUnavailableError => e
      opoo e
      used_formulae_missing = true
      # If the formula doesn't exist: fake the needed formula object name.
      ARGV.named.map { |name| OpenStruct.new name: name, full_name: name }
    end

    checker  = ARGV.flag?("--recursive") ? RecursiveChecker : NonRecursiveChecker
    formulae = ARGV.include?("--installed") ? Formula.installed : Formula
    cached   = !ARGV.include?("--rebuild")

    includes = []
    ignores = []

    ARGV.include?("--include-build")    ? includes << "build?" : ignores << "build?"
    ARGV.include?("--include-optional") ? includes << "optional?" : ignores << "optional?"

    ignores << "recommended?" if ARGV.include? "--skip-recommended"

    uses = used_formulae.map do |formula|
      checker.new(formula, formulae, ignores, includes, cached).check_uses!
    end

    return if uses.empty?
    puts Formatter.columns(uses.sort)
    odie "Missing formulae should not have dependents!" if used_formulae_missing
  end
end
