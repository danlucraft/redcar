module Redcar
  class Project
    class FileList
      attr_reader :path
    
      def self.shared_storage
        @shared_storage ||= begin
          storage = Plugin::SharedStorage.new('shared__ignored_files')
          storage.set_or_update_default('ignored_file_patterns', [/^\./, /\.rbc$/])
          storage.set_or_update_default('not_hidden_files', ['.gitignore', '.gemtest'])
          storage.set_or_update_default('ignored_directory_patterns', [/^\./, /^\.(git|yardoc|svn)$/])
          storage.set_or_update_default('not_hidden_directories', ['.directory_that_should_not_be_hidden'])
          storage.save
        end
      end

      def self.hidden_files_pattern
        ignored_file_patterns
      end

      def self.ignored_file_patterns
        shared_storage['ignored_file_patterns']
      end

      def self.not_hidden_files
        shared_storage['not_hidden_files']
      end

      def self.hide_file?(file)
        file = File.basename(file)
        return false if not_hidden_files.include?(file)
        ignored_file_patterns.any? { |re| file =~ re }
      end
      
      def self.ignored_directory_patterns
        shared_storage['ignored_directory_patterns']
      end

      def self.not_hidden_directories
        shared_storage['not_hidden_directories']
      end

      def self.hide_directory?(dir)
        dir = File.basename(dir)
        return false if not_hidden_directories.include?(dir)
        ignored_directory_patterns.any? { |re| dir =~ re }
      end
      
      def self.hide_file_path?(file_path)
        basename = File.basename(file_path)
        if ignored_file_patterns.any? { |re| basename =~ re } and
          !not_hidden_files.include?(basename)
          return true
        end
        
        dirs = file_path.split("/")[0..-2]
        if ignored_directory_patterns.any? { |re| dirs.any? { |dir| dir =~ re } }
          return true
        end
        false
      end
      
      # Adds a pattern to the ignored_file_patterns option
      #
      # @param [String] file_pattern pattern of the file
      def self.add_hide_file_pattern(file_pattern)
        shared_storage['ignored_file_patterns'] = shared_storage['ignored_file_patterns'] + [Regexp.new(file_pattern)]
      end

      # Adds a pattern to the ignored_directory_patterns option
      #
      # @param [String] directory_pattern pattern of the directory
      def self.add_hide_directory_pattern(directory_pattern)
        shared_storage['ignored_directory_patterns'] = shared_storage['ignored_directory_patterns'] + [Regexp.new(directory_pattern)]
      end

      def initialize(path)
        @path = File.expand_path(path)
        @files = {}
      end
      
      def all_files
        @files.keys
      end
      
      def contains?(file)
        @files[file]
      end
      
      def update(paths=nil)
        if paths
          @files = @files.merge(find(*paths))
        else
          @files = find(path)
        end
      end
      
      def changed_since(time)
        result = {}
        @files.each do |file, mtime|
          if mtime.to_i >= time.to_i - 1
            result[file] = mtime
          end
        end
        result
      end
      
      def inspect
        "#<FileList for #{path.inspect}: #{@files.size} files>"
      end
      
      private
      
      def find(*paths)
        files = {}
        paths.collect!{|d| d.dup}
        while file = paths.shift
          begin
            if File.symlink? file
              real_file = File.expand_path(File.join("..", File.readlink(file)), file)
              real_file = File.expand_path(File.join("..", File.readlink(real_file)), real_file) while File.symlink? real_file
              stat = File.lstat(real_file)
            else
              stat = File.lstat(file)
            end
            
            if stat.directory?
              next if FileList.hide_directory?(file)
            else
              next if FileList.hide_file?(file)
            end
            
            unless stat.directory?
              files[file.dup] = stat.mtime
            end
            
            next unless File.exist?(file)
            
            if stat.directory?
              d = Dir.open(file)
              begin
                for f in d
                  next if f == "." or f == ".."
                  if File::ALT_SEPARATOR and file =~ /^(?:[\/\\]|[A-Za-z]:[\/\\]?)$/
                    f = file + f
                  elsif file == "/"
                    f = "/" + f
                  else
                    f = File.join(file, f)
                  end
                  paths.unshift f.untaint
                end
              ensure
                d.close
              end
            end
          rescue Errno::ENOENT, Errno::EACCES
          end
        end
        files
      end
    end
  end
end
