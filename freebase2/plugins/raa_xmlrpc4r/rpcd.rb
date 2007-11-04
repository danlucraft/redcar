
require "xmlrpc/contrib/rpcservlet"

module FreeBASE

  module RAA

  ##
  # THe XMLRPC_Plugin class provides an XML-RPC handling capability
  # for FreeBASE-based applications.  Uses the xmlrpc4r library.
  #
  class XMLRPC_Plugin
    extend FreeBASE::StandardPlugin
    
    ##
    # Start the XML RPC service.  Called from FreeBASE::Plugin.
    # 
    # plugin:: [FreeBASE::Plugin] The plugin instance
    #
    def self.start(plugin)
      XMLRPC_Plugin.new(plugin)
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def initialize(plugin)
      @plugin = plugin
      @rpcservlet = XMLRPC::Servlet.new
      @plugin["service"].manager = @rpcservlet
      plugin["/protocols/xmlrpc"].manager = self
      plugin["/protocols/xmlrpc"].subscribe self
      @plugin["/protocols/http/RPC2"].data = @rpcservlet
    end
    
    def bind_RPC(prefix, obj_or_signature=nil, &block)
      if block_given?
        @plugin["/protocols/xmlrpc/#{prefix}"].set_proc &block
      else
        @plugin["/protocols/xmlrpc/#{prefix}"].data = obj_or_signature
      end
    end

    def databus_notify(event, slot)
      if event == :notify_data_set
        @plugin.log_info << "mount rpc path #{slot.name} - #{slot.data}"
        @rpcservlet.add_handler(slot.name, slot.data)
      elsif event == :notify_proc_set
        @plugin.log_info << "mount rpc block #{slot.name}"
        @rpcservlet.add_handler(slot.name, &(slot.proc.get_proc))
      end
    end
    
  end
  end
end