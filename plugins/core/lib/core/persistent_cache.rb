
module Redcar
  class PersistentCache
    class << self
      attr_accessor :storage_dir
    end
    
    def self.all
      Dir[File.join(storage_dir, "*.cache")].map do |fn|
        PersistentCache.new(File.basename(fn)[/^(.*)\.cache$/, 1])
      end
    end
    
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
    
    def cache
      if result = read_cache_file
        result
      else
        result = yield
        write_cache_file(Marshal.dump(result))
        result
      end
    end
    
    def clear
      FileUtils.rm_f(cache_file_name)
    end
    
    def cache_file_name
      File.expand_path(File.join(PersistentCache.storage_dir, name)) + ".cache"
    end
    
    private
  
    def write_cache_file(contents)
      FileUtils.mkdir_p(PersistentCache.storage_dir)
      File.open(cache_file_name, "w") {|f| f.puts contents }
    end
    
    def read_cache_file
      if File.exist?(cache_file_name)
        begin
          Marshal.load(File.read(cache_file_name))
        rescue => e
          puts "WARNING: couldn't load #{cache_file_name}, despite it existing."
          puts e.class.name + " " + e.message
          puts e.backtrace
        end
      end
    end
  end
end