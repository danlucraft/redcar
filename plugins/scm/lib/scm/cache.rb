
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
#     c
#   end
# end
module Redcar
  module Scm
    class Cache
      
      def initialize(default=nil)
        @default_value = default
        @blocks = {}
        @timeouts = {}
        @accessed = {}
        @values = {}
      end
      
      def add(name, timeout, &block)
        @blocks[name] = block
        @timeouts[name] = timeout
        @accessed[name] = Time.at(0)
      end
      
      def [](name)
        return @default_value if not @blocks.keys.include?(name)
        
        atime = @accessed[name]
        ctime = Time.now
        
        if (ctime - atime > @timeouts[name])
          @values[name] = @blocks[name].call
          
          @accessed[name] = ctime
        end
        
        @values[name]
      end
      
      def refresh(name=nil)
        keys = name ? [name] : @accessed.keys
        
        keys.each {|k| @accessed[k] = Time.at(0)}
      end
      
    end
  end
end
