
# This is a class used to cache data from the repository, so that it 
# needn't be queried over and over. Use a timeout of a few seconds to
# prevent repeated queries in the same operation, but preserve the 
# ability to retrieve up to date data.
#
# You can call #refresh to reset all the timeouts manually if you
# need to guarantee fresh data
#
# Example usage:
#
# def cache
#   @cache ||= begin
#     c = Cache.new
#     c.add("test", 10) { "Hello world!" }
#     # This block always returns the same thing, so never refresh it
#     c.add("test2") { |name| "Hello #{name}" }
#     c
#   end
# end
#
# cache["test2", "Matthew"] # "Hello Matthew"
module Redcar
  module Scm
    class Cache
      
      #attr_reader :values, :accessed
      
      def initialize(default=nil)
        @default_value = default
        @blocks = {}
        @timeouts = {}
        @accessed = {}
        @values = {}
      end
      
      def add(name, timeout=nil, &block)
        @blocks[name] = block
        @timeouts[name] = timeout
      end
      
      def [](name, *args)
        return @default_value if not @blocks.keys.include?(name)
        
        atime = get_accessed(@accessed, [name, *args])
        ctime = Time.now
        
        if ((not @timeouts[name].nil?) or (not value_exist?(@values, [name, *args]))) and ctime - atime > (@timeouts[name] || 0)
          begin
            set_value(@values, @blocks[name].call(*args), [name, *args])
          rescue
            # dump errors to the console, but otherwise, keep on trucking
            puts $!.backtrace
            set_value(@values, @default_value, [name, *args])
          end
          
          set_accessed(@accessed, ctime, [name, *args])
        end
        
        get_value(@values, [name, *args])
      end
      
      def refresh(times=@accessed)
        times.each do |k, v|
          if v.respond_to? '[]'
            refresh v
          else
            times[k] = Time.at(0)
          end
        end
      end
      
      private
      
      def value_exist?(values, path)
        while path.length > 1
          curr = path.shift
          values = values[curr]
          return false if not values.respond_to? '[]'
        end
        
        return values.keys.include?(path[0])
      end
      
      def get_value(values, path)
        get_from_path(values, path, @default_value)
      end
      
      def get_accessed(times, path)
        get_from_path(times, path, Time.at(0))
      end
      
      def get_from_path(hash, path, default)
        while path.length > 1
          curr = path.shift
          hash = hash[curr]
          return default if not hash.respond_to? '[]'
        end
        
        return hash[path[0]] || default
      end
      
      def set_value(values, value, path)
        set_from_path(values, value, path)
      end
      
      def set_accessed(times, time, path)
        set_from_path(times, time, path)
      end
      
      def set_from_path(hash, value, path)
        while path.length > 1
          curr = path.shift
          hash[curr] ||= {}
          hash = hash[curr]
        end
        
        hash[path[0]] = value
      end
    end
  end
end
