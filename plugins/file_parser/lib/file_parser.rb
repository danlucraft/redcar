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
      file_index = 0
      Find.find(root_path) do |path|
        fullpath = File.expand_path(path)
        path = Pathname.new(fullpath)
        is_excluded_pattern = excluded_patterns.any? { |pattern| fullpath =~ pattern }
        if path.directory?
          Find.prune if excluded_dirs.include?(path.basename.to_s) || is_excluded_pattern
        else
          if path.readable? && !skip_types.find { |st| path.send("#{st}?") }
            unless path.read.is_binary_data? || excluded_files.include?(path.basename.to_s) || is_excluded_pattern
              yield(FileResult.new(path, file_index))
              file_index += 1
            end
          end
        end
      end
    end

    def each_line(&block)
      each_file do |file|
        file.each_line do |line|
          yield(line)
        end
      end
    end

    class FileResult

      attr_reader :path, :index, :lines

      def initialize(path, index)
        @path, @index = path, index
        @lines = @path.read.split("\n")
      end

      def num
        index + 1
      end

      def name
        @project_path ||= Project::Manager.focussed_project.path
        path.realpath.to_s.gsub("#{@project_path}/", '')
      end

      def each_line(&block)
        lines.each_with_index do |text, index|
          yield(LineResult.new(self, index, text))
        end
      end

    end

    class LineResult

      attr_reader :file, :index, :text

      def initialize(file, index, text)
        @file, @index, @text = file, index, text
      end

      def num
        index + 1
      end

      def context(amount = 5)
        before, after = Array.new, Array.new
        if index > 0
          from = (index - amount)
          from = 0 if from < 0
          before = ((from)..(index - 1)).collect { |b_index| LineResult.new(file, b_index, file.lines[b_index]) }
        end
        last_line_index = (file.lines.size - 1)
        if index < last_line_index
          to = (index + amount)
          to = last_line_index if to > last_line_index
          after = ((index + 1)..(to)).collect { |a_index| LineResult.new(file, a_index, file.lines[a_index]) }
        end
        { :before => before, :after => after }
      end

    end

  end
end
