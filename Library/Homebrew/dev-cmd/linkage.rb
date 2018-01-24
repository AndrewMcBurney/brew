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
require "rubygems"

module Homebrew
  module_function

  # Hack to install dependencies
  ENV["BUNDLE_GEMFILE"] = "#{HOMEBREW_LIBRARY_PATH}/test/Gemfile"
  Homebrew.install_gem_setup_path! "bundler"
  system "bundle", "install" unless quiet_system("bundle", "check")

  require "ddtrace"

  def linkage
    tracer = Datadog.tracer

    # Hack to get DataDog tracing on something that's not a web request
    2.times do
      tracer.trace(
        "Homebrew#linkage",
        service: "homebrew",
        resource: "linkage",
        tags: {
          "libraries"  => ARGV.kegs.map(&:name).join(", "),
          "num_libraries" => ARGV.kegs.size,
          "--test"     => ARGV.include?("--test"),
          "--reverse"  => ARGV.include?("--reverse"),
          "--rebuild"  => ARGV.include?("--rebuild"),
        },
      ) do
        ARGV.kegs.each do |keg|
          tracer.trace("package: #{keg.name}", resource: keg.name) do
            ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1

            result = LinkageChecker.new(keg)

            # Force a flush of the 'cache' and check dylibs if the `--rebuild`
            # flag is passed
            result.check_dylibs if ARGV.include?("--rebuild")

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
    end
  end
end
