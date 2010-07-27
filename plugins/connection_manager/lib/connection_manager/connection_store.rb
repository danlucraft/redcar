
module Redcar
  class ConnectionManager
    
    class ConnectionStore
      class ValidationFailedError < StandardError
        def errors
          @errors ||= []
        end
      end
      
      class AlreadyExistsError < StandardError
      end

      attr_reader :connections
      
      def initialize
        @connections = load_connections
      end

      def find(name)
        connections.detect { |c| c.name == name }
      end
      
      def add_connection(name, protocol, host, port, user, path)
        if r = find(name)
          raise AlreadyExistsError.new
        end

        validate_connection(name, protocol, host, port, user, path)
        
        @connections << Connection.new(name, protocol, host, port, user, path)
        
        save_connections
      end
      
      def update_connection(name, protocol, host, port, user, path)
        connection = find(name)
        
        validate_connection(name, protocol, host, port, user, path)

        connection.name     = name
        connection.protocol = protocol
        connection.host     = host
        connection.port     = port
        connection.user     = user
        connection.path     = path
        
        save_connections
      end
      
      def validate_connection(name, protocol, host, port, user, path)
        validation_failed = ValidationFailedError.new
        %w(name protocol host port user).each do |property|
          value = eval(property)
          validation_failed.errors << "#{property} cannot be blank" if !value || value.empty?
        end
        
        if validation_failed.errors.any?
          raise validation_failed
        end
      end

      def delete_connection(name)
        @connections.delete(find(name))
        
        save_connections
      end
      
      private
      
      def load_connections
        (storage["connections"] || []).map do |h|
          Connection.new(h["name"], h["protocol"], h["host"], h["port"], h["user"], h["path"])
        end
      end

      def save_connections
        storage["connections"] = connections.map { |c| c.to_hash }
      end
      
      def storage
        Redcar::Plugin::Storage.new('connection_manager')
      end
    end
  end
end