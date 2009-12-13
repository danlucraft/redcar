module FreeBASE
  module RAA
    ##
    # THe WEBrick_Plugin class provides an HTTP handling capability
    # for FreeBASE-based applications.  Uses the WEBrick library.
    #
    class WEBrick_Plugin
    
      extend FreeBASE::StandardPlugin
      #include WEBrick
      
      ##
      # Try and load the webrick library, and fail plugin transition
      # if it cannot be found.  Called from FreeBASE::Plugin.
      # 
      # plugin:: [FreeBASE::Plugin] The plugin instance
      #
      def self.load(plugin)
        begin
          require "webrick"
          plugin.transition(FreeBASE::LOADED)
        rescue LoadError
          plugin.transition_failure
        end
      end
      
      ##
      # Start the Web server.  Called from FreeBASE::Plugin.
      # 
      # plugin:: [FreeBASE::Plugin] The plugin instance
      #
      def self.start(plugin)
        WEBrick_Plugin.new(plugin)
        plugin.transition(FreeBASE::RUNNING)
      end
      
      ##
      # Stop the Web server.  Called from FreeBASE::Plugin.
      # 
      # plugin:: [FreeBASE::Plugin] The plugin instance
      #
      def self.stop(plugin)
        begin
          plugin["service"].manager.shutdown
        rescue => detail
        end
        plugin.transition(FreeBASE::LOADED)
      end
          
      def initialize(plugin)
        @plugin = plugin
        @httpd = WEBrick::HTTPServer.new(
          :BindAddress => "0.0.0.0",
          :Port => @plugin.properties["port"].to_i, 
          :DocumentRoot => File.join(@plugin.plugin_configuration.base_path, @plugin.properties["web_path"]), 
          :Logger => plugin["/log"].manager)
        Thread.new {@httpd.start}
        plugin["service"].manager=@httpd
        plugin["/protocols/http"].manager = self
        plugin["/protocols/http"].subscribe self
        load_slots(plugin["/protocols/http"])
      end
      
      ##
      # Mount a block to handle http requests at the supplied path
      # path:: [String] The path to handle requests at
      # fileSpec:: [String=nil] The path to serve files from (must be directory)
      # &block:: [Block] The (optional) handler
      #
      # Usage:
      #      db["/protocols/http"].manager.mount("/foo/bar") do |request, response|
      #        response['content-type'] = "text/html"
      #        response.body = "<html><body>Hello World!</html>"
      #      end
      #      #or
      #      db["/protocols/http"].manager.mount("/index.html", "public_html")
      #
      def mount(path, fileSpec=nil, &block)
        path = "/"+path unless path[0]==47 # 47 = '/'
        if fileSpec
          @plugin["/protocols/http#{path}"].data=fileSpec
        else
          @plugin["/protocols/http#{path}"].set_proc &block
        end
      end
      
      def databus_notify(event, slot)
        if event == :notify_data_set
          @plugin.log_info << "mount path #{slot.path[15..-1]} - #{slot.data}"
          @httpd.mount(slot.path[15..-1], WEBrick::HTTPServlet::FileHandler, slot.data, true)
        elsif event == :notify_proc_set
          @plugin.log_info << "mount proc #{slot.path[15..-1]}"
          @httpd.mount_proc(slot.path[15..-1]) do |request, response| 
            begin
              slot.call(request, response)
            rescue
              response['content-type'] = "text/html"
              response.body="<html><body><H1>Exception caught in #{slot.path[15..-1]}</h1><br><B>#{$!}</B><br>#{$!.backtrace.join('<BR>')}</html>"
            end
          end
        end
      end
      
      def load_slots(base)
        base.each_slot do |slot|
          if slot.is_proc_slot?
            @plugin.log_info << "mount proc #{slot.path[15..-1]}"
            @httpd.mount_proc(slot.path[15..-1]) do |request, response| 
              begin
                slot.call(request, response)
              rescue
                response['content-type'] = "text/html"
                response.body="<html><body><H1>Exception caught in #{slot.path[15..-1]}</h1><br><B>#{$!}</B><br>#{$!.backtrace.join('<BR>')}</html>"
              end
            end
          elsif slot.is_data_slot?
            @plugin.log_info << "mount path #{slot.path[15..-1]} - #{slot.data}"
            @httpd.mount(slot.path[15..-1], WEBrick::HTTPServlet::FileHandler, slot.data, false)
          end
          load_slots(slot)
        end
      end
    end
  end
end