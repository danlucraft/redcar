
module Redcar
  class EditTab < Tab
    def self.start(plugin)
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin)
      plugin.transition(FreeBASE::LOADED)
    end

    attr_reader :document, :view
    
    def initialize(pane)
      @view = Redcar::EditView.new
#      @document = Redcar::Document.new(@view)
      super pane, @view
    end
  end
end
