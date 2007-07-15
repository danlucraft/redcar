
module Redcar
  class Image
   
    class Item
      attr_accessor :uuid, :version, :type, :tags, :data
      
      def [](key)
        @data[key]
      end
    end
  
    attr_reader :cache_dir, :source_globs, :items, :timestamps
    
    def initialize(options)
      @cache_dir = options[:cache_dir]
      @source_globs = options[:sources]
      @timestamps = {}
      @items = {}
      load
      cache
    end
    
    def each_source_file
      @source_globs.each do |glob|
        Dir[glob].each do |filename|
          yield filename
        end
      end
    end
    
    def load
      if cached = load_cache
        @cache_dir = cached.cache_dir
        @source_globs += cached.source_globs
        @source_globs.uniq!
        @items = cached.items
        @timestamps = cached.timestamps
        load_updates
      else
        load_afresh
      end
    end
    
    def load_afresh
      each_source_file do |filename|
        @timestamps[filename] = File.mtime(filename)
        YAML.load(File.read(filename)).each do |uuid, v|
          @items[uuid] = v
        end
      end
    end
    
    def load_updates
      each_source_file do |filename|
        if !@timestamps[filename] or
            File.mtime(filename) > @timestamps[filename]
          new_data = YAML.load(File.read(filename))
          new_data.each do |uuid, v|
            if self.include?(uuid)
              @items[uuid][:tags] += v[:tags]
              @items[uuid][:tags].uniq!
              v[:definitions].each do |defn|
                unless self[uuid, defn[:version], defn[:type]]
                  @items[uuid][:definitions] << defn
                end
              end
            else
              @items[uuid] = v
            end
          end
        end
      end
    end
    
    def load_cache
      if File.exists? cache_file
        Marshal.load(File.read(cache_file))
      end
    end
    
    def cache
      File.open(cache_file, "w") do |f|
        f.puts Marshal.dump(self)
      end
    end
    
    def cache_file
      @cache_dir + "/cache.img"
    end
    
    def include?(uuid)
      @items.keys.include? uuid
    end
    
    def [](id, version=nil, type=nil)
      get_item(id, version, type)
    end
    
    def get_item(id, version=nil, type=nil)
      return nil unless @items[id]
      item = Item.new
      item.uuid = id
      item.tags = @items[id][:tags]
      if version and type
        item.version = version
        item.type = type
        defn = @items[id][:definitions].find do |i|
          i[:version] == version and i[:type] == type
        end
        return nil unless defn
        item.data = defn[:data]
      elsif version
        item = Item.new
        item.uuid = id
        item.version = version
        defn = @items[id][:definitions].find do |i|
          i[:version] == version
        end
        return nil unless defn
        item.data = defn[:data]
        item.type = defn[:type]
      else
        item = Item.new
        item.uuid = id
        defn = @items[id][:definitions].sort_by {|i| i[:version] }.last
        item.type = defn[:type]
        item.version = defn[:version]
        item.data = defn[:data]
      end
      return nil unless item.data
      item
    end
    
    def with_tag(tag)
      items = []
      @items.each do |uuid, defn|
        if defn[:tags].include? tag
          items << get_item(uuid)
        end
      end
      items
    end
    
    def size
      i = 0
      @items.each {|k, v| i += v[:definitions].length}
      i
    end
  end
end


