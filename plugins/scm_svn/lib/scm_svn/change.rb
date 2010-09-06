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

        def tooltip_text
          @path
        end

        def icon
          case @status
          when :conflicted
            File.join(Redcar::ICONS_DIRECTORY, "blue-document--exclamation.png")
          when :indexed
            File.join(Redcar::ICONS_DIRECTORY, "blue-document--plus.png")
          when :deleted
            File.join(Redcar::ICONS_DIRECTORY, "blue-document-shred.png")
          when :changed
            File.join(Redcar::ICONS_DIRECTORY, "blue-document--pencil.png")
          when :missing
            File.join(Redcar::ICONS_DIRECTORY, "question-white.png")
          else
            :file
          end
        end

        def leaf?
          File.file?(@path)
        end

        def status
          [@status]
        end

        def log_status
          c = log_codes[status] || ""
          "#{c} #{path}"
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

        def log_codes
          {
            [:indexed] => "A",
            [:changed] => "M",
            [:deleted] => "D",
            [:missing] => "?",
            [:conflicted] => "G"
          }
        end
      end
    end
  end
end
