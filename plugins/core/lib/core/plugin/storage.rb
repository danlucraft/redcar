
module Redcar
  class Plugin
    class Storage
    
      extend Forwardable
      
      def_delegators :@storage, :[], :[]=, :keys
      
      def self.storage_dir
        Core.user_dir
      end

      # Open a storage file or create it if it doesn't exist.
      #
      # @param [String] a (short) name, should be suitable for use as a filename
      def initialize(name)
        @name    = name
        @storage = {}
        rollback
      end

      # Save the storage to disk.
      def save
        File.open(path, "w") { |f| YAML.dump(@storage, f) }
        self
      end

      # Rollback the storage to the latest revision saved to disk or empty it if
      # it hasn't been saved.
      def rollback
        if File.exists?(path)
          @storage = YAML.load_file(path)
        else
          @storage = {}
        end
        self
      end
      
      private
      
      def path
        File.join(Storage.storage_dir, @name + ".yaml")
      end
    end
  end
end

