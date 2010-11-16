
class ProjectSearch
  class WordSearchController < ProjectSearch::RegexSearchController
  
    def title
      "Project Search"
    end
    
    def search_copy
      "Search for complete words only"
    end
    
    def show_literal_match_option?
      false
    end

    def num_context_lines
      @settings['context_lines']
    end
    
    def search(query, literal_match, match_case, with_context)
      @query = query
      ProjectSearch.storage['recent_queries'] = add_or_move_to_top(@query, ProjectSearch.storage['recent_queries'])
      ProjectSearch.storage['literal_match'] = (@literal_match = true)
      ProjectSearch.storage['match_case'] = (@match_case = (match_case == 'true'))
      ProjectSearch.storage['with_context'] = (@with_context = (with_context == 'true'))
      @regexp = create_regexp

      # kill any existing running search to prevent memory bloat
      Thread.kill(@thread) if @thread
      @thread = nil
      @thread = Thread.new do
        bits = query.
                  gsub(/[^\w]/, " ").
                  gsub("_", " ").
                  split(/\s/).
                  map {|b| b.strip}.
                  reject {|b| b == "" or org.apache.lucene.analysis.standard.StandardAnalyzer::STOP_WORDS_SET.to_a.include?(b)}
        if bits.any?
          project = Redcar::Project::Manager.focussed_project
          index   = ProjectSearch.indexes[project.path].lucene_index
          doc_ids = nil
          bits.each do |bit|
            new_doc_ids = index.find(:contents => bit.downcase).map {|doc| doc.id }
            doc_ids = doc_ids ? (doc_ids & new_doc_ids) : new_doc_ids
          end
          
          initialize_search_output
          if doc_ids.any?
            add_initial_table
            file_num = 1
            last_matching_line_num = nil
            
            doc_ids.each do |doc_id|
              context            = {:before => []}
              parsing_new_file   = true
              matched_lines      = false
              last_matching_file = doc_id
              @line_index = 0 # reset line row styling
              contents = File.read(doc_id).split(/\n|\r/)
              need_context_after = 0
              contents.each_with_index do |line, line_num_minus_1|
                line_num = line_num_minus_1 + 1
                
                if @with_context
                  context[:before].shift if context[:before].length == num_context_lines + 1
                  context[:before] << [line, line_num]
                end
                
                unless matching_line?(line)
                  if need_context_after > 0
                    render_line(file_num, line_num, doc_id, line)
                    need_context_after -= 1
                  end
                  next
                end
                
                add_initial_table
                
                if parsing_new_file
                  increment_file_results_count
                  add_break_row # if matched_lines
                  render_file_heading(doc_id, file_num)
                  @line_index = 0 # reset line row styling
                end
                
                if @with_context && !parsing_new_file && (line_num - last_matching_line_num) > (num_context_lines * 2)
                  render_divider(file_num)
                end
                
                if @with_context
                  context[:before].each { |line, line_num| render_line(file_num, line_num, doc_id, line) }
                  context[:before].clear
                end
                render_line(file_num, line_num, doc_id, line)
                
                increment_line_results_count
                
                matched_lines          = true
                parsing_new_file       = false
                last_matching_line_num = line_num
                if @with_context
                  need_context_after     = num_context_lines
                end
              end
              file_num += 1
            end
            remove_initial_blank_tr
          else
            render_no_results
          end
          hide_spinner
        else
          puts "Your query reduced to nothing."
          Redcar.update_gui do
            Redcar::Application::Dialog.message_box("Your query reduced to nothing.", :type => :error)
          end
        end
        Thread.kill(@thread) if @thread
        @thread = nil
      end
      nil
    end
  end
end