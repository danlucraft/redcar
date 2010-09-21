
module Redcar
  module Macros
    class ActionSequence
      attr_reader :actions
      attr_reader :skip_length
      
      def initialize(actions, skip_length)
        @actions = actions
        @skip_length = skip_length
      end
      
      def run_in(edit_view)
        edit_view.document.compound do
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
  end
end