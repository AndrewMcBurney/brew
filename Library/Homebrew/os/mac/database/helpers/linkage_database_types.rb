#
# Helper module used in `LinkageDatabase` and `LinkageStore` for concretion
# specific internal logic
#
module LinkageDatabaseTypes
  # `GENERALIZED_LINKAGE_TYPES` are rows which have a 'label' attribute which is
  # NULL. There is a constraint check in `LinkageDatabase` to ensure these types
  # do not have a label:
  #
  #   - CHECK (label IS NULL OR (type IN (#{hash_types})))
  #
  # @return [Array[String]]
  GENERALIZED_TYPES = %w[
    system_dylibs variable_dylibs broken_dylibs undeclared_deps unnecessary_deps
  ].freeze

  # HASH_LINKAGE_TYPES are rows which have a 'label' attribute which is NOT
  # NULL. There is a constraint check in `LinkageDatabase` to ensure these types
  # have a label:
  #
  #   - CHECK (label IS NULL OR (type IN (#{hash_types})))
  #
  # @return [Array[String]]
  HASH_LINKAGE_TYPES = %w[
    brewed_dylibs reverse_links
  ].freeze
end
