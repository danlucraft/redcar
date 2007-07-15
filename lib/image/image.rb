
module Redcar
  class Image
    def initialize(options)
      @cache_dir = options[:cache_dir]
      @source_glob = options[:sources]
    end
  end
end


