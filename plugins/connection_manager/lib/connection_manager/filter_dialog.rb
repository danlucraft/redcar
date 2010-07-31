module Redcar
  class ConnectionManager
    class FilterDialog < FilterListDialog
      MANAGER_NAME = "(Connection Manager)"
      
      def initialize
        super
      end
      
      def update_list(query)
        if query == ""
          connection_names
        else
          filter_and_rank_by(connection_names, query, 1000)
        end
      end
      
      def selected(text, _)
        close
        open_connection(text)
      end
      
      private
      
      def open_connection(name)
        ConnectionManager.open_connection(store.find(name))
      end
      
      def store
        ConnectionManager::ConnectionStore.new
      end
      
      def connection_names
        ["(Connection Manager)"] + store.connections.map {|con| con.name }
      end
    end
  end
end