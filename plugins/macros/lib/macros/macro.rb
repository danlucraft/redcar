
module Redcar
  class Macro
    attr_reader :actions
    attr_writer :name
    
    def initialize(name, actions)
      @actions = actions.reject {|action| action.is_a?(Redcar::Macros::StartStopRecordingCommand)}
      @name = name
    end
    
    def name
      @name
    end
    
    def run
      run_in EditView.focussed_edit_view
    end

    def run_in(edit_view)
      Macros.last_run = self
      Macros.last_run_or_recorded = self
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
      Redcar.app.repeat_event(:macro_ran)
    end
  end
end
