#:  * `linkage` [`--test`] [`--reverse`] [`--rebuild`] <formula>:
#:    Checks the library links of an installed formula.
#:
#:    Only works on installed formulae. An error is raised if it is run on
#:    uninstalled formulae.
#:
#:    If `--test` is passed, only display missing libraries and exit with a
#:    non-zero exit code if any missing libraries were found.
#:
#:    If `--reverse` is passed, print the dylib followed by the binaries
#:    which link to it for each library the keg references.
#:
#:    If `--rebuild` is passed, flushes sqlite3 db row for 'keg.name' and
#:    forces a check on the dylibs

require "os/mac/linkage_checker"
require "os/mac/linkage_database"

module Homebrew
  module_function

  def linkage
    check = LinkageDatabase.empty?(keys: ARGV.kegs.map(&:name))

    ARGV.kegs.each do |keg|
      ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1
      result = LinkageChecker.new(keg)

      # Force a flush of the 'cache' and check dylibs if the `--rebuild`
      # flag is passed
      result.check_dylibs if check || ARGV.include?("--rebuild")

      if ARGV.include?("--test")
        result.display_test_output
        Homebrew.failed = true if result.broken_dylibs?
      elsif ARGV.include?("--reverse")
        result.display_reverse_output
      else
        result.display_normal_output
      end
    end
  end
end
