module Redcar
  class Application

    class SwitchTabDownCommand < TabCommand

      def execute
        win.focussed_notebook.switch_down
      end
    end

    class SwitchTabUpCommand < TabCommand

      def execute
        win.focussed_notebook.switch_up
      end
    end

    class MoveTabUpCommand < TabCommand

      def execute
        win.focussed_notebook.move_up
      end
    end

    class MoveTabDownCommand < TabCommand

      def execute
        win.focussed_notebook.move_down
      end
    end

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
          CloseTabCommand.new(t).run
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
            CloseTabCommand.new(t).run
          end
        end
      end
    end
    
    # define commands from SelectTab1Command to SelectTab9Command
    (1..9).each do |tab_num|
      const_set("SelectTab#{tab_num}Command", Class.new(Redcar::TabCommand)).class_eval do
        define_method :execute do
          notebook = Redcar.app.focussed_window_notebook
          notebook.tabs[tab_num-1].focus if notebook.tabs[tab_num-1]
        end
      end
    end
  end
end











