module Redcar

  class ApplicationSWT
    class Window
      def sash
        @sash
      end
    end
  end
end

class Sessions

  class Memory
    attr_reader :project, :storage

    def initialize(project)
      @project = project
      @storage = Redcar::Plugin::BaseStorage.new "#{project.path}/.redcar/storage", 'sessions'
      sash.add_selection_listener do |e|
        @current_tree_width = e.x
      end
    end

    def shell(window=self.project.window)
      window.controller.shell
    end

    def sash(window=self.project.window)
      window.controller.sash
    end

    def last_bounds
      return unless storage["bounds"]
      rect = storage["bounds"]
      Java::OrgEclipseSwtGraphics::Rectangle.new(
        rect["x"], rect["y"], rect["width"], rect["height"])
    end

    def tree_width
      return unless storage["tree_width"]
      storage["tree_width"].to_i
    end

    def save(window)
      self.last_bounds = shell(window).getBounds
      storage["tree_width"] = @current_tree_width if @current_tree_width
      storage.save
    end

    def recall
      if last_bounds
        shell.setBounds last_bounds
      end
      if tree_width
        sash.layout_data.left = Swt::Layout::FormAttachment.new 0, tree_width
        shell.layout
      end
      self
    end

    private

    def last_bounds=(rect)
      storage["bounds"] = {
        "x"      => rect.x,
        "y"      => rect.y,
        "width"  => rect.width,
        "height" => rect.height
      }
    end
  end

end
