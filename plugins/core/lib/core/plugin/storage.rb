require 'yaml'

module Redcar
  class Plugin
    class Storage
      def self.windows?
        (RUBY_PLATFORM =~ /(mswin32|mingw32)/) ||
          ((RUBY_PLATFORM == 'java') &&
           (java.lang.System.getProperty('os.name') =~ /Windows/)
          )
      end

      ##
      # Determine where the storage directory is (if any)
      #
      # @return [String] The storage directory path
      def self.storage_dir
        $FREEBASE_APPLICATION = "redcar" unless $FREEBASE_APPLICATION
        if windows?
          if ENV['USERPROFILE'].nil?
            userdir = "C:/My Documents/.redcar/storage/"
            Dir.mkdir(userdir) unless File.directory?(userdir)
          else
            userdir = File.join(ENV['USERPROFILE'], $FREEBASE_APPLICATION.downcase, "storage")
          end
        else
          userdir = File.join(ENV['HOME'],".#{$FREEBASE_APPLICATION.downcase}", "storage") unless ENV['HOME'].nil?
        end
        return userdir
      end

      ##
      # Open a new storage or create it if it doesn't exist.
      def initialize(name)
        @path = File.join(self.class.storage_dir, name + ".yaml")
        rollback
      end

      ##
      # Save the storage to disk.
      def save
        File.open(@path, File::RDWR | File::CREAT) { |f| YAML.dump(@storage||{}, f) }
        self
      end

      ##
      # Rollback the storage to the latest revision saved to disk or empty it if
      # it hasn't been saved.
      def rollback
        if File.exists?(@path)
          @storage = YAML.load_file(@path) || {}
        else
          @storage = {}
        end
        self
      end

      def method_missing(symbol, *args)
        if @storage.respond_to?(symbol)
          @storage.send(symbol, *args)
        else
          super
        end
      end
    end
  end
end
