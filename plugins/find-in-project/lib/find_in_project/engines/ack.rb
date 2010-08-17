module Redcar
  class FindInProject
    class Engines
      class Ack
        def self.detect
          exe_path = `which ack`.strip
          (exe_path =~ /^\//) ? exe_path : false
        end

        def self.exe_path
          Redcar::FindInProject.storage['ack_path']
        end

        def self.version
          `#{exe_path} --version`.split("\n")[0].split(' ').last
        end

        def self.search(query, options, match_case, with_context)
          raise "Error: Trying to search using ack but ack has not been detected. Please edit the ack_path setting." if exe_path.empty?

          args = ["--nocolor --nopager --nogroup -RH"] # no color, recursive, with filename
          args[0] << 'i' unless match_case # case insensitive
          args << options unless options.empty?

          path = Project::Manager.focussed_project.path
          organise_results(`cd #{path}; #{exe_path} #{args.join(' ')} "#{query}" .`)
        end

        def self.organise_results(raw)
          results = Hash.new
          raw.split("\n").each do |line|
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
