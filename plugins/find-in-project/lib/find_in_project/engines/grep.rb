module Redcar
  class FindInProject
    class Engines
      class Grep
        def self.detect
          exe_path = `which grep`.strip
          (exe_path =~ /^\//) ? exe_path : false
        end

        def self.exe_path
          Redcar::FindInProject.storage['grep_path']
        end

        def self.version
          `#{exe_path} --version`.split("\n")[0].split(' ').last
        end

        def self.search(query, options, match_case, with_context)
          raise "Error: Trying to search using grep but grep has not been detected. Please edit the grep_path setting." if exe_path.empty?

          args = ["-RHInE"] # recursive, with filename, no binaries, with line numbers, extended regex
          args[0] << 'i' unless match_case # case insensitive
          args << '--before-context=2 --after-context=2' if with_context # 2 lines before and after each result
          args << options unless options.empty?

          path = Project::Manager.focussed_project.path
          organise_results(`cd #{path}; #{exe_path} #{args.join(' ')} "#{query}" .`)
        end

        def self.organise_results(raw)
          results = Hash.new
          raw.split("\n").each do |line|
            if line == '--'
              @divide_next = true
            else
              line =~ /^(.*)[\:\-](\d+)[\:\-](.*)$/
              file, line, text = $1, $2.to_i, $3
              results[file] ||= Array.new
              if @divide_next
                results[file] << [:divide, ''] if file == @last_file
                @divide_next = false
              end
              results[file] << [line, text]
              @last_file = file
            end
          end
          results.sort
        end
      end
    end
  end
end
