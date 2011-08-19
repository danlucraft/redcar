
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

    def lucene_index_dir
      File.join(@project.config_dir, "lucene")
    end

    def delete
      FileUtils.rm(timestamp_file_path)
      FileUtils.rm_r(lucene_index_dir)
      load
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

    MAX_FILE_SIZE = 500 * 1024

    def update
      changed_files = @project.file_list.changed_since(last_updated)
      @last_updated = Time.now
      changed_files.reject! do |fn, ts|
        fn.index(@project.config_dir) or Redcar::Project::FileList.hide_file_path?(fn)
      end
      Lucene::Transaction.run do
        @lucene_index ||= Lucene::Index.new(lucene_index_dir)
        begin
          @lucene_index.field_infos[:contents][:store] = true
          @lucene_index.field_infos[:contents][:tokenized] = true
          changed_files.each do |fn, ts|
            begin
              next if File.size(fn) > MAX_FILE_SIZE
              pre_contents = File.new(fn).read(200)
              unless !pre_contents or BinaryDataDetector.binary?(pre_contents)
                contents = File.read(fn)
                adjusted_contents = contents.gsub(/\.([^\s])/, '. \1')
                @lucene_index << { :id => fn, :contents => adjusted_contents }
              end
            rescue => e
              Redcar.log.error("[project_search] error indexing file #{fn}: #{e.message}")
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