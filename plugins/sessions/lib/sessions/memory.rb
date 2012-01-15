class Sessions
  class Memory
    attr_reader :project, :storage

    def initialize(project)
      @project = project
      @storage = project.storage('sessions')
    end

    def last_bounds
      return unless storage["bounds"]
      rect = storage["bounds"]
      [rect["x"], rect["y"], rect["width"], rect["height"]]
    end

    def tree_width
      return unless storage["tree_width"]
      storage["tree_width"].to_i
    end

    def save(window)
      bs = window.bounds
      storage["bounds"] = {
        "x"      => bs[0],
        "y"      => bs[1],
        "width"  => bs[2],
        "height" => bs[3]
      }
      storage["tree_width"] = window.treebook_width
      storage.save
    end

    def recall
      if last_bounds
        project.window.bounds = last_bounds
      end
      if tree_width
        project.window.treebook_width = tree_width
      end
      self
    end

  end

end
