require 'find'
require 'pathname'

module Redcar
  class FileParser

    attr_accessor :root_path, :excluded_dirs, :excluded_files, :excluded_patterns, :skip_types

    def initialize(root_path, options = {})
      self.root_path = root_path.to_s
      self.excluded_dirs = options['excluded_dirs'] || ['.git', '.svn', '.redcar']
      self.excluded_files = options['excluded_files'] || []
      self.excluded_patterns = options['excluded_patterns'] || [/tags$/, /\.log$/]
      self.skip_types = options['skip_types'] || [:executable, :mountpoint, :symlink, :zero]
    end

    def each_file(&block)
      Find.find(root_path) do |path|
        fullpath = File.expand_path(path)
        path = Pathname.new(fullpath)
        is_excluded_pattern = excluded_patterns.any? { |pattern| fullpath =~ pattern }
        if path.directory?
          Find.prune if excluded_dirs.include?(path.basename.to_s) || is_excluded_pattern
        else
          if path.readable? && !skip_types.find { |st| path.send("#{st}?") }
            yield(path) unless path.read.is_binary_data? || excluded_files.include?(path.basename.to_s) || is_excluded_pattern
          end
        end
      end
    end

    def each_line(&block)
      file_no = 0
      each_file do |file|
        file_no += 1
        line_no = 0
        file.each_line do |line|
          line_no += 1
          yield(line, line_no, file, file_no)
        end
      end
    end

  end
end
