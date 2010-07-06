
module Redcar
  module HtmlController
    include Redcar::Observable
    
    def execute(script)
      notify_listeners(:execute_script, script)
    end
  end
end