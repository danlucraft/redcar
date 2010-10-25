module Redcar

  class OpenDefaultApp
  
    def self.project_context_menus(tree, node, controller)
      Menu::Builder.build do
        item ("Open Default App"){OpenDefaultAppCommand.new(node.path).run }
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
		file  = java::io::File.new(path)
        desktop = Desktop.get_desktop
		desktop.open(file)
      end
    end
    
  end
end