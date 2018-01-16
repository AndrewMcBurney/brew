require "set"
require "keg"
require "formula"
require "os/mac/linkage_store"

class LinkageChecker
  attr_reader :keg, :formula, :store

  def initialize(keg, formula = nil)
    @keg     = keg
    @formula = formula || resolve_formula(keg)
    @store   = LinkageStore.new
  end

  # 'Hash type' cache values

  def brewed_dylibs
    @brewed_dylibs ||= store.fetch_hash_values!(
      type: "brewed_dylibs", keys: [keg.name],
    )
  end

  def reverse_links
    @reverse_links ||= store.fetch_hash_values!(
      type: "reverse_links", keys: [keg.name],
    )
  end

  # 'Path-type' cached values

  def system_dylibs
    @system_dylibs ||= store.fetch_path_values!(
      type: "system_dylibs", keys: [keg.name],
    )
  end

  def broken_dylibs
    @broken_dylibs ||= store.fetch_path_values!(
      type: "broken_dylibs", keys: [keg.name],
    )
  end

  def variable_dylibs
    @variable_dylibs ||= store.fetch_path_values!(
      type: "variable_dylibs", keys: [keg.name],
    )
  end

  def undeclared_deps
    @undeclareddeps ||= store.fetch_path_values!(
      type: "undeclared_deps", keys: [keg.name],
    )
  end

  def unnecessary_deps
    @unnecessary_deps ||= store.fetch_path_values!(
      type: "unnecessary_deps", keys: [keg.name],
    )
  end

  def check_dylibs
    reset_dylibs!

    @keg.find do |file|
      next if file.symlink? || file.directory?
      next unless file.dylib? || file.binary_executable? || file.mach_o_bundle?

      # weakly loaded dylibs may not actually exist on disk, so skip them
      # when checking for broken linkage
      file.dynamically_linked_libraries(except: :LC_LOAD_WEAK_DYLIB).each do |dylib|
        @reverse_links[dylib] << file
        if dylib.start_with? "@"
          @variable_dylibs << dylib
        else
          begin
            owner = Keg.for Pathname.new(dylib)
          rescue NotAKegError
            @system_dylibs << dylib
          rescue Errno::ENOENT
            next if harmless_broken_link?(dylib)
            @broken_dylibs << dylib
          else
            tap = Tab.for_keg(owner).tap
            f = if tap.nil? || tap.core_tap?
              owner.name
            else
              "#{tap}/#{owner.name}"
            end
            @brewed_dylibs[f] << dylib
          end
        end
      end
    end

    @undeclared_deps, @unnecessary_deps = check_undeclared_deps if formula
    store_dylibs!
  end

  def check_undeclared_deps
    filter_out = proc do |dep|
      next true if dep.build?
      next false unless dep.optional? || dep.recommended?
      formula.build.without?(dep)
    end
    declared_deps = formula.deps.reject { |dep| filter_out.call(dep) }.map(&:name)
    declared_dep_names = declared_deps.map { |dep| dep.split("/").last }
    undeclared_deps = @brewed_dylibs.keys.reject do |full_name|
      name = full_name.split("/").last
      next true if name == formula.name
      declared_dep_names.include?(name)
    end
    undeclared_deps.sort do |a, b|
      if a.include?("/") && !b.include?("/")
        1
      elsif !a.include?("/") && b.include?("/")
        -1
      else
        a <=> b
      end
    end
    unnecessary_deps = declared_dep_names.reject do |full_name|
      name = full_name.split("/").last
      next true if Formula[name].bin.directory?
      @brewed_dylibs.keys.map { |x| x.split("/").last }.include?(name)
    end
    [undeclared_deps, unnecessary_deps]
  end

  def display_normal_output
    display_items "System libraries", system_dylibs
    display_items "Homebrew libraries", brewed_dylibs
    display_items "Variable-referenced libraries", variable_dylibs
    display_items "Missing libraries", broken_dylibs
    display_items "Undeclared dependencies with linkage", undeclared_deps
    display_items "Dependencies with no linkage", unnecessary_deps
  end

  def display_reverse_output
    return if @reverse_links.empty?
    sorted = @reverse_links.sort
    sorted.each do |dylib, files|
      puts dylib
      files.each do |f|
        unprefixed = f.to_s.strip_prefix "#{@keg}/"
        puts "  #{unprefixed}"
      end
      puts unless dylib == sorted.last[0]
    end
  end

  def display_test_output
    display_items "Missing libraries", @broken_dylibs
    display_items "Possible unnecessary dependencies", @unnecessary_deps
    puts "No broken dylib links" if @broken_dylibs.empty?
  end

  def broken_dylibs?
    !@broken_dylibs.empty?
  end

  def undeclared_deps?
    !@undeclared_deps.empty?
  end

  def unnecessary_deps?
    !@unnecessary_deps.empty?
  end

  private

  # Whether or not dylib is a harmless broken link, meaning that it's
  # okay to skip (and not report) as broken.
  def harmless_broken_link?(dylib)
    # libgcc_s_* is referenced by programs that use the Java Service Wrapper,
    # and is harmless on x86(_64) machines
    [
      "/usr/lib/libgcc_s_ppc64.1.dylib",
      "/opt/local/lib/libgcc/libgcc_s.1.dylib",
    ].include?(dylib)
  end

  # Display a list of things.
  # Things may either be an array, or a hash of (label -> array)
  def display_items(label, things)
    return if things.empty?
    puts "#{label}:"
    if things.is_a? Hash
      things.sort.each do |list_label, list|
        list.sort.each do |item|
          puts "  #{item} (#{list_label})"
        end
      end
    else
      things.sort.each do |item|
        puts "  #{item}"
      end
    end
  end

  def resolve_formula(keg)
    Formulary.from_keg(keg)
  rescue FormulaUnavailableError
    opoo "Formula unavailable: #{keg.name}"
  end

  # Helper function to reset dylib values when building cache
  #
  # @return [nil]
  def reset_dylibs!
    @system_dylibs    = Set.new
    @broken_dylibs    = Set.new
    @variable_dylibs  = Set.new
    @brewed_dylibs    = Hash.new { |h, k| h[k] = Set.new }
    @reverse_links    = Hash.new { |h, k| h[k] = Set.new }
    @undeclared_deps  = []
    @unnecessary_deps = []
    store.flush_cache_for_keys!(keys: [keg.name])
  end

  # Updates store with library values
  #
  # @return [nil]
  def store_dylibs!
    store.update!(
      key: keg.name,
      array_linkage_values: {
        system_dylibs: @system_dylibs,
        variable_dylibs: @variable_dylibs,
        broken_dylibs: @broken_dylibs,
        undeclared_deps: @undeclared_deps,
        unnecessary_deps: @unnecessary_deps,
      },
      hash_linkage_values: {
        brewed_dylibs: @brewed_dylibs,
        reverse_links: @brewed_dylibs,
      },
    )
  end
end
