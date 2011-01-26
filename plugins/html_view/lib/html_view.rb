
require 'html_view/commands'
require 'html_view/browser_bar'
require 'html_view/html_tab'
require 'html_controller'
require 'html_view/default_controller'
require 'json'

module Redcar
  class HtmlView
    def self.default_css_path
      File.expand_path(File.join(Redcar.root, %w(plugins html_view assets redcar.css)))
    end

    def self.jquery_path
      File.expand_path(File.join(Redcar.root, %w(plugins html_view assets jquery-1.4.min.js)))
    end

    def self.keymaps
      map = Redcar::Keymap.build("main", [:osx, :linux, :windows]) do
        link "Alt+Shift+B", ToggleBrowserBar
        link "Alt+Shift+P", FileWebPreview
      end
      [map]
    end

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "File" do
          item "Web Preview", :command => FileWebPreview, :priority => 8
        end
        sub_menu "View" do
          item "Toggle Browser Bar", :command => ToggleBrowserBar, :priority => 11
        end
      end
    end

    def self.storage
      @storage ||= begin
         storage = Plugin::Storage.new('html_view')
         storage.set_default('use_external_browser_for_urls', false)
         storage
      end
    end

    def self.show_browser_bar?
      if win = Redcar.app.focussed_window and
        win.speedbar and win.speedbar.is_a?(BrowserBar)
        return true
      end
      false
    end

    def self.tidy_url(url)
      unless url.include?("://")
        if File.exists?(url)
          url = "file://#{url}"
        elsif project = Redcar::Project::Manager.focussed_project and
          relpath = File.join(project.path,url) and
          File.exists?(relpath)
          url = "file://#{relpath}"
        else
          url = "http://#{url}"
        end
      end
      url
    end

    attr_reader :controller

    def initialize(html_tab)
      @html_tab = html_tab
      @html_tab.add_listener(:controller_action, &method(:controller_action))
    end

    def controller=(new_controller)
      @controller = new_controller
      @html_tab.title = controller.title
      func = RubyFunc.new(@html_tab.controller.browser, "rubyCall")
      func.controller = @controller
      refresh
      attach_controller_listeners
    end
    
    def refresh
      controller_action("index")
    end

    def attach_controller_listeners
      @controller.add_listener(:reload_index) { controller_action("index") }

      @controller.add_listener(:execute_script) do |script|
        result = nil
        begin
          Redcar.update_gui do
            begin
              browser = @html_tab.controller.browser
              unless browser.is_disposed
                result = browser.evaluate(script)
              end
            rescue => e
              puts e.message
              puts e.backtrace
            end
          end
        rescue => e
          puts e.message
          puts e.backtrace
        end
        result
      end
    end

    def controller_action(action_name, params=nil)
      text = nil
      begin
        action_method_arity = controller.method(action_name).arity
        text = if action_method_arity == 0
                 controller.send(action_name)
               elsif action_method_arity == 1
                 controller.send(action_name, params)
               end
      rescue => e
        text = <<-HTML
          Sorry, there was an error.<br />
          <pre><code>
            #{e.message}
            #{e.backtrace}
          </code></pre>
        HTML
      end
      if text
        unless @html_tab.controller.browser.disposed
          @html_tab.controller.browser.set_text(text.to_s + setup_javascript_listeners)
        end
      end
    end

    def contents=(source)
      @html_tab.controller.browser.set_text(source)
    end

    private

    class RubyFunc < Swt::Browser::BrowserFunction
      def function(args)
        begin
          if result = controller.send(*args.to_a)
            return JSON(result)
          else
            return "{}"
          end
        rescue JSON::GeneratorError => e
          nil
        rescue Object => e
          puts "caught in controller"
          puts e.message
          puts e.backtrace
        end
      end

      attr_accessor :controller
    end

    # TODO: remove this method once we have a default layout that
    #       has <%= javascript_controller_actions %>
    def setup_javascript_listeners
      controller.javascript_controller_actions
    end
  end
end
