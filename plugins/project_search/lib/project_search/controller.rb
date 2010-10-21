

class ProjectSearch
  class Controller < Redcar::FindInProject::Controller
    
    def search(query, literal_match, match_case, with_context)
      p [:search, query, literal_match, match_case, with_context]
      @query = query
      bits = query.gsub(/[^\w]/, " ").gsub("_", " ").split(/\s/).map {|b| b.strip}
      project = Redcar::Project::Manager.focussed_project
      index   = ProjectSearch.indexes[project.path]
      doc_ids = nil
      bits.each do |bit|
        puts "searching for #{bit}"
        new_doc_ids = index.find(:contents => bit.downcase).map {|doc| doc.id }
        doc_ids = doc_ids ? (doc_ids & new_doc_ids) : new_doc_ids
      end
      
      initialize_search_output
      if doc_ids.any?
        add_initial_table
        file_num = 1
        doc_ids.each do |doc_id|
          increment_file_results_count
          @line_index = 0 # reset line row styling
          add_break_row
          render_file_heading(doc_id, file_num)
          contents = File.readlines(doc_id)
          contents.each_with_index do |line, line_num|
            if line.index(query)
              puts "#{doc_id} @ #{line_num}"
              render_line(file_num, line_num, doc_id, line)
              increment_line_results_count
            end
          end
          file_num += 1
        end
      else
        render_no_results
      end
      hide_spinner
      nil
    end
  end
end