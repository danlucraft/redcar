
module Redcar
  class Macro
    attr_reader :actions
    attr_writer :name
    
    def initialize(actions, name=nil)
      @actions = actions.reject {|action| action.is_a?(Redcar::Macros::StartStopRecordingCommand)}
      @name = name
    end
    
    def name
      @name || "Nameless Macro :("
    end
    
    def run
      run_in EditView.focussed_edit_view
    end

    def run_in(edit_view)
      actions.each do |action|
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
