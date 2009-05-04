require 'dbus'
require File.dirname(__FILE__) + "/../vendor/dbus_fix"
require 'uri'
require 'cgi'

DBUS_CONFIG = {
  :default => {
    :service   => "com.redcareditor.app",
    :path      => "/com/redcareditor/app",
    :interface => "com.redcareditor.app"
  },
  :features => {
    :service   => "com.redcareditor.features",
    :path      => "/com/redcareditor/features",
    :interface => "com.redcareditor.features"
  }
}

module Redcar
  class DBus < ::DBus::Object
    def self.namespace
      return @namespace if @namespace
      if in_features_process? or 
          ARGV.include?("--dbus-features")
        @namespace = :features
      else
        @namespace = :default
      end
    end
    
    def self.export_service
      @bus          = ::DBus::SessionBus.instance
      service      = @bus.request_service(DBUS_CONFIG[namespace][:service])
      exported_obj = new(DBUS_CONFIG[namespace][:path])
      
      service.export(exported_obj)      
    end
    
    dbus_interface DBUS_CONFIG[namespace][:interface] do
      dbus_method :focus do
        Gtk.queue do
          Redcar.win.window.focus Gdk::Event::CURRENT_TIME
        end
      end
      
      dbus_method :open, "in path:s, in line:s, in column:s" do |path, line, column|
        App.log.info "open(#{path.inspect})"
        Gtk.queue do
          # TODO: fix this hardcoded reference
          tab = OpenTabCommand.new(path).do
          if tab
            line = 1 if line.blank?
            column = 1 if column.blank?
            line = line.to_i
            column = column.to_i
            line -= 1
            column -= 1
            tab.goto(line, column) 
          end
        end
      end
      
      dbus_method :new_tab, "in contents:s" do |contents|
        Gtk.queue do
          App.log.info "new_tab(#{contents.inspect})"
          tab = NewTab.new.do
          tab.buffer.text = contents
        end
      end
      
      dbus_method :debug, "in contents:s" do |contents|
        App.log.info "debug(#{contents.inspect})"
      end
    end
    
    # Return instance of dbus control object on success, none on failure
    def self.try_export_service
      puts "exporting dbus service: #{namespace}"
      Redcar::DBus.export_service
    rescue ::DBus::Connection::NameRequestError
      bus     = ::DBus::SessionBus.instance
      service = bus.service(DBUS_CONFIG[namespace][:service])
      object  = service.object(DBUS_CONFIG[namespace][:path])
      object.introspect
      object.default_iface = DBUS_CONFIG[namespace][:interface]
      any_directories = ARGV.any? {|arg| File.exist?(arg) and File.directory?(arg)}
      object.debug(ARGV.inspect)
      object.debug(any_directories.inspect)
      object.debug("namespace: #{namespace}")
      unless any_directories
        ARGV.each do |arg|
          object.debug(arg)
          protocol = (namespace == :features ? "redcar-features" : "redcar")
          begin
            uri = URI.parse(arg)
            if uri.scheme == protocol
              query = CGI.parse(uri.query)
              if uri.host == "open" and query["url"]
                file_uri = query["url"].first
                path = file_uri.split("://").last
                object.open(File.expand_path(path), 
                            query["line"].first.to_s, query["column"].first.to_s)
              end
            end
          rescue URI::InvalidURIError => e
            object.debug(e.inspect)
          end
        end
        ARGV.each do |arg|
          if File.exist?(arg)
            object.open(File.expand_path(arg), "1", "1")
          end
        end
        if $stdin_contents and $stdin_contents.length > 0
          object.new_tab($stdin_contents.to_s)
        end
        object.focus
        exit(0)
      end
    end
  end
end

