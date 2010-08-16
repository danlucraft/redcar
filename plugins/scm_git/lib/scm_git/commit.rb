
module Redcar
  module Scm
    module Git
      class Commit
        include Redcar::Scm::ScmMirror::Commit
        
        def initialize(commit)
          @commit = commit
        end
        
        def text
          @commit.sha[0, 7] + " - " + @commit.message.split("\n").first
        end
      end
    end
  end
end
