
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
      previous_block_selection_mode = Swt.sync_exec { edit_view.document.block_selection_mode? }
      p [:start_in_block_selection_mode?, start_in_block_selection_mode?]
      runnable = Swt::RRunnable.new do
        edit_view.document.block_selection_mode = start_in_block_selection_mode?
      end
      Redcar::ApplicationSWT.display.asyncExec(runnable)
      Redcar::ApplicationSWT.display.syncExec(empty_runnable)

      actions.each do |action|
        runnable = Swt::RRunnable.new do
          begin
            p action
            case action
            when Fixnum
              edit_view.type_character(action)
            when Symbol
              edit_view.invoke_action(action)
            when DocumentCommand
              action.run(:env => {:edit_view => edit_view})
            end
          rescue => e
            puts e.type
            puts e.message
            puts e.backtrace
            raise e
          end
        end
        Redcar::ApplicationSWT.display.asyncExec(runnable)
        Redcar::ApplicationSWT.display.syncExec(empty_runnable)
      end
      runnable = Swt::RRunnable.new do
        edit_view.document.block_selection_mode = previous_block_selection_mode
      end
      Redcar::ApplicationSWT.display.asyncExec(runnable)
      Redcar::ApplicationSWT.display.syncExec(empty_runnable)
      Redcar.app.repeat_event(:macro_ran)
    end
    
    def empty_runnable
      Swt::RRunnable.new {}
    end
  
  end
end
