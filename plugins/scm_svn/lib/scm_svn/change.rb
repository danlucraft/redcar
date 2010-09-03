module Redcar
  module Scm
    module Subversion
      class Change
        include Redcar::Scm::ScmChangesMirror::Change

        def initialize(path,status,children,diff)
          @path = path
          @status = status
          @children = children
          @diff = diff
        end

        def text
         File.basename(@path)
        end

        def leaf?
          File.file?(@path)
        end

        def status
          @status
        end

        def path
          @path
        end

        def children
          @children
        end

        def diff
          @diff
        end
      end
    end
  end
end
