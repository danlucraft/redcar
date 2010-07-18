module Redcar
  class FindInProject
    class Engines
      class Grep
        def self.detect
          grep_path = `which grep`.strip
          (grep_path =~ /^\//) ? grep_path : false
        end

        def self.grep_path
          Redcar::FindInProject.storage['grep_path']
        end

        def self.grep_version
          `#{grep_path} --version`.split("\n")[0].split(' ').last
        end

        def self.search(query, options, match_case)
          raise "Error: Trying to search using grep but grep has not been detected. Please edit the grep_path setting." if grep_path.empty?

          args = ["-RHInE"] # recursive, with filename, no binaries, with line numbers, extended regex
          args[0] << 'i' unless match_case  # case insensitive
          args << options unless options.empty?

          path = Project::Manager.focussed_project.path
          output = `cd #{path}; grep #{args.join(' ')} "#{query}" .`

          results = Hash.new
          output.split("\n").each do |line|
            parts = line.split(':')
            file, line, text = parts.shift, parts.shift.to_i, parts.join(':')
            results[file] ||= Array.new
            results[file] << [line, text]
          end
          results.sort
        end
      end
    end
  end
end
