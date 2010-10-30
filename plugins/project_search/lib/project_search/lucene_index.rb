
class ProjectSearch
  class LuceneIndex
    attr_accessor :last_updated, :lucene_index
    
    def initialize(project)
      @project     = project
      @has_content = false
      load
    end
    
    def timestamp_file_path
      File.join(@project.config_dir, 'lucene_last_updated')
    end
    
    def load
      @last_updated = Time.at(0)
      if File.exist?(timestamp_file_path)
        @last_updated = Time.at(File.read(timestamp_file_path).chomp.to_i)
        @has_content = true
      end
    end
    
    def dump
      File.open(timestamp_file_path, "w") do |fout|
        fout.puts(last_updated.to_i.to_s)
      end
    end
    
    def has_content?
      @has_content
    end
    
    def update
      changed_files = @project.file_list.changed_since(last_updated)
      @last_updated = Time.now
      changed_files.reject! do |fn, ts|
        fn.index(@project.config_dir)
      end
      Lucene::Transaction.run do 
        @lucene_index ||= Lucene::Index.new(File.join(@project.config_dir, "lucene")) 
        begin
          @lucene_index.field_infos[:contents][:store] = true 
          @lucene_index.field_infos[:contents][:tokenized] = true          changed_files.each do |fn, ts|
            unless File.basename(fn)[0..0] == "." or fn.include?(".git")
              contents = File.read(fn)
              unless BinaryDataDetector.binary?(contents[0..200])
                adjusted_contents = contents.gsub(/\.([^\s])/, '. \1')
                @lucene_index << { :id => fn, :contents => adjusted_contents }
              end
            end
          end
          @lucene_index.commit
          @has_content = true
        rescue => e
          puts e.message
          puts e.backtrace
        end
      end
      dump
    end
    
  end
end