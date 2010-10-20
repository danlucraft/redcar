
$:.push(File.dirname(__FILE__) + "/../vendor/lucene/lib")
require 'lucene'

class ProjectSearch
  
  Lucene::Config.use do |config| 
    config[:store_on_file] = true 
    config[:storage_path]  = ""
    config[:id_field]      = :id
  end
  
  class LuceneRefresh < Redcar::Task
    def initialize(project)
      @file_list   = project.file_list
      @project     = project
    end
    
    def description
      "#{@project.path}: refresh index"
    end
    
    def execute
      return if @project.remote?
      files = @file_list.all_files
      files.delete(::File.join(@project.config_dir, 'tags'))
      Lucene::Transaction.run do 
        index = 
          (ProjectSearch.indexes[@project.path] ||= 
            Lucene::Index.new(File.join(@project.config_dir, "lucene")) )
        index.field_infos[:contents][:store] = true 
        index.field_infos[:contents][:tokenized] = true        index.field_infos[:contents][:analyzer] = :whitespace        files.each do |fn|
          if fn =~ /rb$/
            index << { :id => fn, :contents => File.read(fn) }
          end
        end
      end
    end
  end
  
  def self.project_refresh_task_type
    LuceneRefresh
  end
  
  class SearchCommand < Redcar::Command
    def execute
      result = Redcar::Application::Dialog.input("Search for", "query: ")
      query = result[:value]
      bits = query.gsub(/[^\w]/, " ").gsub("_", " ").split(/\s/).map {|b| b.strip}
      project = Redcar::Project::Manager.focussed_project
      index   = ProjectSearch.indexes[project.path]
      doc_ids = nil
      bits.each do |bit|
        puts "searching for #{bit}"
        new_doc_ids = index.find(:contents => bit.downcase).map {|doc| doc.id }
        doc_ids = doc_ids ? (doc_ids & new_doc_ids) : new_doc_ids
      end
      
      doc_ids.each do |doc_id|
        contents = File.read(doc_id)
        if offset = contents.index(query)
          puts "#{doc_id} @ #{offset}"
        end
      end    end
  end

  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Project" do
        item "Search", :command => ProjectSearch::SearchCommand
      end
    end
  end

  def self.indexes
    @indexes ||= {}
  end
end


