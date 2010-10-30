module Redcar

  class OpenDefaultApp

    def self.project_context_menus(tree, node, controller)
      Menu::Builder.build do
        if node and node.path
          item ("Open Default App"){OpenDefaultAppCommand.new(node.path).run }
        end
      end
    end

    class OpenDefaultAppCommand < Redcar::Command
      import java.awt.Desktop

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def execute(options=nil)
        @path ||= options[:value]
        begin
		    file  = java::io::File.new(path)
        desktop = Desktop.get_desktop
    		desktop.open(file)
        rescue Object => e
          Application::Dialog.message_box("A default application could not be found for this type of file.")
        end
      end
    end

  end
end
