
module Redcar
  class ConnectionManager
    
    class PrivateKeyStore
      def self.paths
        auto_detected_keys + store_keys
      end
      
      def self.auto_detected_keys
        paths = []
        default_key_globs.each do |default_key_glob|
          Dir[default_key_glob].each do |filename|
            first = File.open(filename).read(100)
            if first =~ /PRIVATE KEY/
              paths << filename
            end
          end
        end
        paths
      end
      
      def self.store_keys
        PrivateKeyStore.new.paths
      end
      
      def self.default_key_globs
        [File.join(Redcar.home_dir, ".ssh", "*")]
      end
      
      class ValidationError < StandardError
        def errors
          @errors ||= []
        end
      end
      
      def initialize
        @private_key_files = load_private_key_files
      end
      
      def paths
        @private_key_files
      end
      
      def add_private_key(path)
        path = File.expand_path(path)
        validate_private_key(path)
        
        @private_key_files << path
        
        save_private_key_files
      end
      
      def remove_private_key(path)
        path = File.expand_path(path)
        @private_key_files.delete(path)
        
        save_private_key_files
      end
      
      def validate_private_key(path)
        validation_error = ValidationError.new
        unless File.exist?(path) and File.file?(path)
          validation_error.errors << "File not found."
          raise validation_error
        end
        
        begin
          Net::SSH::KeyFactory.load_private_key(path)
        rescue OpenSSL::PKey::PKeyError
          validation_error.errors << "File does not contain a private key."
          raise validation_error
        end
      end
        
      private
      
      def load_private_key_files
        storage["private_keys"] || []
      end

      def save_private_key_files
        storage["private_keys"] = @private_key_files
      end
      
      def storage
        Redcar::Plugin::Storage.new('connection_manager')
      end
    end
  end
end