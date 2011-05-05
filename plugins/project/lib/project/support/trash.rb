module Redcar
  class Project
    # FIXME: XXX: This is outright ugly. See the note on Redcar::Project::OpenCommand
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
        end

        def windows(file)
          system %{ cscript //nologo #{WINDOWS_SUPPORT_JS} "#{file.gsub('/', "\\")}" }
        end

        # Move paths to FreeDesktop Trash can
        # See <http://www.ramendik.ru/docs/trashspec.html>
        def linux(file)
          trashdir = File.expand_path("#{(ENV['XDG_DATA_HOME'] || '~/.local/share')}/Trash")
          FileUtils.mkdir_p("#{trashdir}/files")
          FileUtils.mkdir_p("#{trashdir}/info")

          # Create unique filename
          deleted_path = "#{trashdir}/files/#{File.basename(file)}"
          while File.exist?(deleted_path)
            deleted_path = "#{trashdir}/files/#{File.basename(file)}-#{Time.now.to_i}"
          end

          # Write trashinfo
          trashinfo = "#{trashdir}/info/#{File.basename(deleted_path)}.trashinfo"
          File.open(trashinfo, 'w') do |f|
            f << "[Trash Info]\n"
            f << "Path=#{file}\n"
            f << "DeletionDate=#{DateTime.now.strftime('%Y%m%dT%H:%M:%S')}\n"
          end

          begin
            FileUtils.mv(file, deleted_path)
          rescue SystemCallError
            # We cannot move - this usually happens if the file is on another partition
            # The proper way to go would be to check for a partition-topdir .Trash directory
            # We do not support this right now - the spec allows us to copy-and-remove in this case
            if File.directory? file
              # FileUtils.cp_r copies src-dir always _into_ dest-dir
              # But we want src-dir's contents to be the contents of dest-dir
              FileUtils.mkdir_p deleted_path
              FileUtils.cp_r("#{file}/.", deleted_path)
            else
              FileUtils.cp(file, deleted_path)
            end
            FileUtils.rm_rf(file)
          end

          return true
        rescue SystemCallError
          FileUtils.rm(trashinfo) if File.exist? trashinfo
          return false
        end
      end
    end
  end
end