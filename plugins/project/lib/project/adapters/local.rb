module Redcar
  class Project
    module Adapters
      class Local
        attr_accessor :path
        
        def lazy?
          false
        end
        
        def touch(new_file_path)
          FileUtils.touch(new_file_path)
        end
        
        def mkdir(new_dir_path)
          FileUtils.mkdir(new_dir_path)
        end
        
        def mv(path, new_path)
          FileUtils.mv(path, new_path)
        end
        
        def real_path
          File.expand_path(path)
        end
        
        def exist?
          File.exist?(@path)
        end
        
        def file?(path=@path)
          File.file?(path)
        end
        
        def directory?(path=@path)
          File.directory?(path)
        end
        
        def fetch_contents(path, force=false)
          Dir.glob("#{path}/*", File::FNM_DOTMATCH)
        end

        def load(file)
          File.open(file, 'rb') do |f|; f.read; end
        end

        def save(file, contents)
          File.open(file, "wb") {|f| f.print contents }
        end
        
        def mtime(file)
          File.stat(file).mtime
        end
        
        def exists?(file)
          File.exists?(file)
        end
        
        def load_contents(file)
          File.open(@path, 'rb') do |f|; f.read; end
        end
        
        def save_contents(file)
          File.open(@path, "wb") {|f| f.print contents }
        end
      end
    end
  end
end