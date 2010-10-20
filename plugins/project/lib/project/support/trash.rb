module Redcar
  class Project
    module Trash
      WINDOWS_SUPPORT_JS = File.expand_path("../recycle.js", __FILE__)

      class << self
        def recycle(file)
          file = File.expand_path(file)
          case Redcar.platform
          when :windows then windows(file)
          when :osx then osx(file)
          when :linux then linux(file)
          end
        end

        def osx(file)
          system %{ osascript -e "tell application \\"Finder\\"
                      move (POSIX file \\"#{file}\\") to the trash
                    end tell" }
          true
        end

        def windows(file)
          system %{ cscript //nologo #{WINDOWS_SUPPORT_JS} "#{file}" }
          true
        end

        # Move paths to FreeDesktop Trash can
        # See <http://www.ramendik.ru/docs/trashspec.html>
        def linux(file)
          trashdir = File.expand_path("#{(ENV['XDG_DATA_HOME'] || "~/.local/share")}/Trash")
          FileUtils.mkdir_p("#{trashdir}/files")
          FileUtils.mkdir_p("#{trashdir}/info")

          # Create unique filename
          deleted_path = "#{trashdir}/files/#{File.basename(file)}"
          while File.exist?(deleted_path)
            deleted_path = "#{trashdir}/files/#{File.basename(file)}-#{Time.now.to_i}"
          end

          # Write trashinfo
          File.open("#{trashdir}/info/#{File.basename(deleted_path)}.trashinfo", 'w') do |f|
            f << "[Trash Info]\n"
            f << "Path=#{file}\n"
            f << "DeletionDate=#{DateTime.now.strftime('%Y%m%dT%H:%M:%S')}\n"
          end

          FileUtils.mv(file, deleted_path)
          true
        end
      end
    end
  end
end