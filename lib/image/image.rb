
module Redcar
  class Image
   
    class Item
      attr_accessor :uuid, :type, :data
      
      def created
        @data[:created]
      end
      
      def created=(v)
        @data[:created] = v
      end
      
      def tags=(v)
        @data[:tags] = v
      end
      
      def tags
        @data[:tags]
      end
      
      def method_missing(sym, *args, &block)
        @data.send(sym, *args, &block)
      end
    end
  
    attr_reader :cache_dir, :source_globs, :items, :timestamps
    
    def initialize(options)
      process_params(options, :cache_dir => nil,
                              :sources   => [])
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
          @items[uuid] = {:source => v, :user => nil}
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
              if v[:created] > self[uuid][:created]
                self[uuid] = v
              end
            else
              @items[uuid] = {:source => v, :user => nil}
            end
          end
        end
      end
    end
    
    def load_cache
      if File.exists? cache_file
        YAML.load(File.read(cache_file))
      end
    end
    
    def cache
      File.open(cache_file, "w") do |f|
        f.puts self.to_yaml
      end
    end
    
    def cache_file
      @cache_dir + "/cache.img"
    end
    
    def include?(uuid)
      @items.keys.include? uuid
    end
    
    def [](id, type=nil)
      get_item(id, type)
    end
    
    def get_item(id, type=nil)
      return nil unless @items[id]
      item = Item.new
      item.uuid = id
      if type
        item.type = type
        defn = @items[id][type]
        return nil unless defn
        item.data = defn
      else
        item = Item.new
        item.uuid = id
        defn = @items[id][:user]
        item.type = :user
        unless defn
          defn = @items[id][:source]
          item.type = :source
        end
        return nil unless defn
        item.data = defn
      end
      item
    end
    
    def find_with_tag(tag)
      items = []
      @items.each do |uuid, types|
        defn = types[:user] || types[:source]
        if defn[:tags].include? tag
          items << get_item(uuid)
        end
      end
      items
    end
    
    def find_with_tags(*tags)
      items = []
      @items.each do |uuid, types|
        all = true
        defn = types[:user] || types[:source]
        tags.each do |tag|
          all = false unless defn[:tags].include? tag
        end
        if all
          items << get_item(uuid)
        end
      end
      items
    end
    
    def size
      @items.keys.length
    end
    
    def []=(id, data)
      if @items[id]
        defn = @items[id][:user] || @items[id][:source]
        data[:tags] ||= defn[:tags]
        @items[id][:user] = data
      end
    end
    
    def add(data)
      uuid = UUID.new
      data[:tags] ||= []
      @items[uuid] = {:user => data}
      uuid
    end
    
    def tag(uuid, *tags)
      if include? uuid
        @items[uuid][:user] ||= @items[uuid][:source]
        @items[uuid][:user][:tags] += tags
        @items[uuid][:user][:tags].uniq!
      else
        raise ArgumentError, "no Image item with uuid #{uuid}"
      end
    end
  end
end


