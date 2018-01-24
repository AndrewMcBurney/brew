require "pstore"

#
# LinkageDatabase is a module to interface with the pstore module
#
module LinkageDatabase
  # Expose linkage database through LinkageDatabase module
  #
  # @return [PStore] db
  def db
    @db ||= PStore.new "#{HOMEBREW_CACHE}/linkage.pstore"
  end
end
