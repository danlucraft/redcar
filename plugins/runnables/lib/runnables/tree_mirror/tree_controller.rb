module Redcar
  class Runnables
    class TreeController < Redcar::Project::ProjectTreeController

      def right_click(tree, node)
        controller = self
        menu = Menu.new
        Redcar.plugin_manager.objects_implementing(:runnables_context_menus).each do |object|
          case object.method(:runnables_context_menus).arity
          when 1
            menu.merge(object.runnables_context_menus(node))
          when 2
            menu.merge(object.runnables_context_menus(tree, node))
          when 3
            menu.merge(object.runnables_context_menus(tree, node, controller))
          else
            puts("Invalid runnables_context_menus hook detected in "+object.class.name)
          end
        end
        Application::Dialog.popup_menu(menu, :pointer)
      end

      def activated(tree, node)
        case node
        when Runnable
          Runnables.run_process(@project.home_dir, node.command, node.text, node.output)
        when HelpItem
          tab = Redcar.app.focussed_window.new_tab(HtmlTab)
          tab.go_to_location("http://github.com/redcar/redcar/wiki/Users-Guide---Runnables")
          tab.title = "Runnables Help"
          tab.focus
        end
      end
    end
  end
end