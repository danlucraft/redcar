
module Redcar
  class Macro
    attr_accessor :actions, :name
    
    def initialize(actions, name="Nameless Macro :(")
      @actions = actions
      @name = name
    end

    def run_in(edit_view)
      puts "running #{name}"
      actions[1..-1].each do |action|
        case action
        when Fixnum
          p [:character, action]
          edit_view.controller.mate_text.get_text_widget.doContent(action)
          edit_view.controller.mate_text.get_text_widget.update
        when Symbol
          const = EditViewSWT::ALL_ACTIONS[action]
          p [:action, action, const]
          edit_view.controller.mate_text.get_text_widget.invokeAction(const)
        when DocumentCommand
          p [:command, action]
          action.run(:env => {:edit_view => edit_view})
        end
      end
    end
  end
  
end
