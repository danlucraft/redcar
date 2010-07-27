
module Redcar
  class ConnectionManager
    
    class Controller
      include Redcar::HtmlController
      
      attr_reader :store, :private_key_store
      
      def initialize
        @store = ConnectionStore.new
        @private_key_store = PrivateKeyStore.new
      end
      
      def title
        "Connections"
      end
      
      def index
        rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "..", "views", "index.html.erb")))
        rhtml.result(binding)
      end
      
      def add_connection(name, protocol, host, port, user, path)
        store.add_connection(name, protocol, host, port, user, path)

        success_response
      rescue ConnectionStore::AlreadyExistsError
        { 
          'success' => false, 
          'error' => "Connection #{name} already exists. Choose another name and try again." 
        }
      rescue ConnectionStore::ValidationFailedError => e
        validation_failed_response(e)
      end

      def update_connection(name, protocol, host, port, user, path)
        store.update_connection(name, protocol, host, port, user, path)

        success_response
      rescue ConnectionStore::ValidationFailedError => e
        validation_failed_response(e)
      end
      
      def delete_connection(name)
        store.delete_connection(name)
        
        success_response
      end
      
      def get_connection(name)
        store.find(name).to_hash
      end
      
      def add_private_key_file(path)
        private_key_store.add_private_key(path)
      rescue PrivateKeyStore::ValidationError => e
        validation_failed_response(e)
      end

      def remove_private_key_file(path)
        private_key_store.remove_private_key(path)
      end

      def activate_connection(name)
        connection = store.find(name)
        Project::Manager.connect_to_remote(
            connection.protocol, connection.host,
            connection.user, connection.path,
            PrivateKeyStore.paths
          )
      end
      
      private
      
      def connections
        store.connections
      end
      
      def auto_detected_private_key_files
        PrivateKeyStore.auto_detected_keys
      end
      
      def private_key_files
        private_key_store.paths
      end
      
      def success_response
        { 'success' => true }
      end
      
      def validation_failed_response(e)
        {
          'success' => false,
          'error' => "Please fix the following errors:<ul>#{e.errors.map {|msg| "<li>#{msg}</li>"}}<ul>"
        }
      end
    end
  end
end