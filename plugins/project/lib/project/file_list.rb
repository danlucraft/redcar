module Redcar
  class Project
    class FileList
      attr_reader :path
    
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
            unless file =~ /\.git|\.yardoc|\.svn/
              unless stat.directory?
                files[file.dup] = stat.mtime
              end
              next unless File.exist? file
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
            end
          rescue Errno::ENOENT, Errno::EACCES
          end
        end
        files
      end
    end
  end
end