
module Redcar
  class Plugin
    class Storage
      class << self
        attr_writer :storage_dir
      end
    
      def self.storage_dir
        @user_dir ||= File.join(Redcar.user_dir, "storage")
      end

      # Open a storage file or create it if it doesn't exist.
      #
      # @param [String] a (short) name, should be suitable for use as a filename
      def initialize(name)
        @name    = name
        unless File.exists?(Storage.storage_dir)
          FileUtils.mkdir_p(Storage.storage_dir)
        end
        rollback
      end

      # Save the storage to disk.
      def save
				File.open(path, "w") { |f| YAML.dump(@storage, f) }
        update_timestamp
        self
      end

      # Rollback the storage to the latest revision saved to disk or empty it if
      # it hasn't been saved.
      def rollback
        if File.exists?(path)
          @storage = YAML.load_file(path)
          raise 'storage file is corrupted--please delete ' + path unless @storage.is_a? Hash
          update_timestamp
        else
          @storage = {}
        end
        self
      end
      
      # retrieve key value
      # note: it does not re-read from disk before returning you this value
      def [](key)
        if @last_modified_time
          if File.stat(path()).mtime != @last_modified_time
            rollback
          end
        end
        @storage[key]
      end
      
      # set key to value
      # note: it automatically saves this to disk
      def []=(key, value)
        @storage[key] = value
        save
        value
      end
      
      def set_default(key, value)
        unless @storage.has_key?(key)
          self[key] = value
        end
        value
      end
      
      def keys
        @storage.keys
      end
      
      private
      
      def path
        File.join(Storage.storage_dir, @name + ".yaml")
      end
      
      def update_timestamp
        @last_modified_time = File.stat(path()).mtime
      end
    end
  end
end

