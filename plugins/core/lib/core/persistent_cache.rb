
module Redcar
  class PersistentCache
    class << self
      attr_accessor :storage_dir
    end
    
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
    
    def cache
      if File.exist?(cache_file_name)
        Marshal.load(File.read(cache_file_name))
      else
        result = yield
        write_cache_file(Marshal.dump(result))
        result
      end
    end
    
    def cache_file_name
      File.expand_path(File.join(PersistentCache.storage_dir, name)) + ".cache"
    end
    
    private
  
    def write_cache_file(contents)
      FileUtils.mkdir_p(PersistentCache.storage_dir)
      File.open(cache_file_name, "w") {|f| f.puts contents }
    end
  end
end