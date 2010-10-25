
require 'clipboard_viewer/clipboard_bar'
require 'clipboard_viewer/browser_controller'

module Redcar
  class ClipboardViewer

    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Clipboard" do
            item "Clipboard Viewer Bar", :command => OpenClipboardBar    , :priority => 18
            item "Clipboard Browser"   , :command => OpenClipboardBrowser, :priority => 18
          end
        end
      end
    end

    def self.storage
      @storage ||= begin
         storage = Plugin::Storage.new('clipboard_viewer')
         storage.set_default('chars_to_display', 50)
         storage.set_default('lines_to_display', 3)
         storage
      end
    end

    class OpenClipboardBar < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        speedbar = Redcar::ClipboardViewer::ClipboardBar.new
        window.open_speedbar(speedbar)
      end
    end

    class OpenClipboardBrowser < Redcar::Command

      def initialize(list=Redcar.app.clipboard)
        @list = list || []
      end

      def execute
        controller = BrowserController.new(@list)
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
  end
end