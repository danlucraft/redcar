module Redcar
  class Application

    class CloseTabCommand < TabCommand
      def initialize(tab=nil)
        @tab = tab
      end

      def tab
        @tab || super
      end

      def execute
        Redcar.app.call_on_plugins(:close_tab_guard, tab) do |guard|
          return unless guard
        end
        close_tab
        @tab = nil
      end

      private

      def close_tab
        win = tab.notebook.window
        tab.close
        # this will break a lot of features:
        #if win.all_tabs.empty? and not Project::Manager.in_window(win)
        #  win.close
        #end
      end
    end

    class CloseAll < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        tabs = window.all_tabs
        tabs.each do |t|
          Redcar::Top::CloseTabCommand.new(t).run
        end
      end
    end

    class CloseOthers < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        current_tab = Redcar.app.focussed_notebook_tab
        tabs = window.all_tabs
        tabs.each do |t|
          unless t == current_tab
            Redcar::Top::CloseTabCommand.new(t).run
          end
        end
      end
    end
  end
end