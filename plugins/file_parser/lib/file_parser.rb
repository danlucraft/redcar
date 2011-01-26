require 'pathname'

module Redcar
  class FileParser

    attr_accessor :root_path, :excluded_dirs, :excluded_files, :excluded_patterns, :skip_types

    def self.measure(message, &block)
      require 'benchmark'
      r = nil
      b = Benchmark.measure { r = yield }
      puts message + ": " + b.to_s
      r
    end

    def initialize(root_path, options = {})
      self.root_path = root_path.to_s
      self.excluded_dirs = options['excluded_dirs'] || ['.git', '.svn', '.redcar']
      self.excluded_files = options['excluded_files'] || []
      self.excluded_patterns = options['excluded_patterns'] || [/tags$/, /\.log$/]
      self.skip_types = options['skip_types'] || [:executable, :mountpoint, :symlink, :zero]
    end

    def directory?(pathname)
      f = java.io.File.new(pathname.path.to_java)
      f.directory?
    end
    
    def each_file(&block)
      file_index, excluded_paths = 0, []
      structure = Dir.glob("#{root_path}/**/*", File::FNM_DOTMATCH)
      structure.sort.each do |path|
        fullpath = File.expand_path(path)
        next if excluded_paths.any? { |ep| fullpath =~ /^#{Regexp.escape(ep)}(\/|$)/ }
        path = Pathname.new(fullpath)
        is_excluded_pattern = excluded_patterns.any? { |pattern| fullpath =~ pattern }
        if directory?(path)
          excluded_paths << path if excluded_dirs.include?(path.basename.to_s) || is_excluded_pattern
        else
          skipped = skip_types.find { |st| path.send("#{st}?") }
          excluded = excluded_files.include?(path.basename.to_s) || is_excluded_pattern
          unless !path.readable? || path.read.is_binary_data? || skipped || excluded
            yield(FileResult.new(path, file_index))
            file_index += 1
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

      attr_reader :path, :index, :lines, :lines_size

      def initialize(path, index)
        @path, @index = path, index
        @lines = @path.read.split("\n")
        @lines_size = @lines.size
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

      def inspect
        "#<FileResult path=#{path.to_s} index=#{index} lines=#{lines.size}>"
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
        from, to = (index - amount), (index + amount)
        from = 0 if from < 0
        last_line_index = (file.lines_size - 1)
        to = last_line_index if to > last_line_index

        before, after, range = Array.new, Array.new, (from..to)
        lines = file.lines[range]
        range.each_with_index do |ri, li|
          next if ri == index
          line = LineResult.new(file, ri, lines[li])
          (ri < index) ? (before << line) : (after << line)
        end

        { :before => before, :after => after }
      end

      def inspect
        "#<LineResult index=#{index} file=#{file.to_s}>"
      end

    end

  end
end
