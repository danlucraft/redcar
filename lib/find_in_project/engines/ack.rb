module Redcar
  class FindInProject
    class Engines
      class Ack
        def self.detect
          ack_path = `which ack`.strip
          (ack_path =~ /^\//) ? ack_path : false
        end

        def self.ack_path
          Redcar::FindInProject.storage['ack_path']
        end

        def self.search(query, options, match_case)
          raise "Error: Trying to search using ack but ack has not been detected. Please edit the ack_path setting." if ack_path.empty?

          args = ["--nocolor --nopager --nogroup -RH"] # no color, recursive, with filename
          args[0] << 'i' if match_case      # case insensitive
          args << options unless options.empty?

          path = Project::Manager.focussed_project.path
          output = `cd #{path}; ack #{args.join(' ')} "#{query}" .`

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
