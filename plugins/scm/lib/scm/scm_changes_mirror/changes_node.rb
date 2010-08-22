
module Redcar
  module Scm
    class ScmChangesMirror
      class ChangesNode
        include Redcar::Tree::Mirror::NodeMirror
        
        attr_reader :change_types
        
        def initialize(repo, change_types)
          @repo = repo
          @change_types = change_types
        end
        
        def text
          case @change_types
          when :indexed
            @repo.translations[:indexed_changes]
          when :unindexed
            @repo.translations[:unindexed_changes]
          when :all
            @repo.translations[:uncommited_changes]
          end
        end
        
        def icon
          :directory
        end
        
        def leaf?
          false
        end
        
        def children
          case @change_types
          when :indexed
            @repo.indexed_changes
          when :unindexed
            @repo.unindexed_changes
          when :all
            @repo.uncommited_changes
          end
        end
      end
    end
  end
end
