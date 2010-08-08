module Redcar
  class Project
    module Adapters
      class Local
        def touch(new_file_path)
          FileUtils.touch(new_file_path)
        end
        
        def mkdir(new_dir_path)
          FileUtils.mkdir(new_dir_path)
        end
        
        def mv(path, new_path)
          FileUtils.mv(path, new_path)
        end
        
        def file?(path)
          File.file?(path)
        end
        
        def directory?(path)
          File.directory?(path)
        end
        
        def empty_directory?(path)
          Dir.glob("#{path}/*", File::FNM_DOTMATCH).length <= 2
        end
        
        def fetch_contents(path, force=false)
          Dir.glob("#{path}/*", File::FNM_DOTMATCH).map do |fn|
            is_dir = directory?(fn)
            hash = {
              :fullname => fn,
              :type => (is_dir ? :dir : :file),
            }
            if is_dir
              hash[:empty] = empty_directory?(fn)
            end
            hash
          end
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
        
        def delete(file)
          FileUtils.rm_rf(file)
        end
        
        def load_contents(file)
          File.open(file, 'rb') do |f|; f.read; end
        end
        
        def save_contents(file)
          File.open(file, "wb") {|f| f.print contents }
        end
        
        def refresh_operation(tree)
          yield
        end
      end
    end
  end
end