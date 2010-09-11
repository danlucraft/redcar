
module Redcar
  class Macro
    attr_accessor :actions, :name
    
    def initialize(actions, name="Nameless Macro :(")
      @actions = actions
      @name = name
    end

    def run_in(edit_view)
      actions[1..-1].each do |action|
        case action
        when Fixnum
          edit_view.type_character(action)
        when Symbol
          edit_view.invoke_action(action)
        when DocumentCommand
          action.run(:env => {:edit_view => edit_view})
        end
      end
    end
  end
  
end
