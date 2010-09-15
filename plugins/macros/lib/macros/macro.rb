
module Redcar
  class Macro
    attr_reader :actions
    attr_writer :name
    
    def initialize(name, actions, start_in_block_selection_mode)
      @actions = actions.reject {|action| action.is_a?(Redcar::Macros::StartStopRecordingCommand)}
      @name                          = name
      @start_in_block_selection_mode = start_in_block_selection_mode
    end
    
    def name
      @name
    end
    
    def start_in_block_selection_mode?
      @start_in_block_selection_mode
    end
    
    def run
      run_in EditView.focussed_edit_view
    end

    def run_in(edit_view)
      Macros.last_run = self
      Macros.last_run_or_recorded = self
      previous_block_selection_mode = edit_view.document.block_selection_mode?
      p self
      edit_view.document.block_selection_mode = start_in_block_selection_mode?
      p edit_view.document.to_s
      p edit_view.document.cursor_offset, edit_view.document.selection_offset
      actions.each do |action|
        p action
        case action
        when Fixnum
          edit_view.type_character(action)
        when Symbol
          edit_view.invoke_action(action)
        when DocumentCommand
          action.run(:env => {:edit_view => edit_view})
        end
        ApplicationSWT.display.update
        p [edit_view.document.to_s, edit_view.document.controller.styledText.text]
      end
      p edit_view.document.to_s
      edit_view.document.block_selection_mode = previous_block_selection_mode
      Redcar.app.repeat_event(:macro_ran)
    end
  end
end
