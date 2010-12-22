
class ProjectSearch
  class WordSearch
    attr_reader :query_string, :context_size, :project
    
    def initialize(project, query_string, match_case, context_size)
      @project      = project
      @query_string = query_string
      @match_case   = !!match_case
      @context_size = context_size
    end
    
    def match_case?
      @match_case
    end
    
    def context?
      @context_size > 0
    end
    
    def matching_line?(line)
      line =~ regex
    end
    
    def regex
      @regex ||= begin
        regexp_text = Regexp.escape(@query_string)
        match_case? ? /#{regexp_text}/ : /#{regexp_text}/i
      end
    end
    
    def on_file_results(&block)
      @on_file_results_block = block
    end
    
    def generate_results
      hits = []
      doc_ids.each do |doc_id|
        next unless File.exist?(doc_id)
        contents = File.read(doc_id).split(/\n|\r/)
        pre_context = []
        hits_needing_post_context = []
        remove_hits = []
        file_hits = []
        contents.each_with_index do |line, line_num|
          hits_needing_post_context.each do |hit|
            hit.post_context << line
            if hit.post_context.length == context_size
              remove_hits << hit
            end
          end
          hits_needing_post_context -= remove_hits
          
          if matching_line?(line)
            hit = Hit.new(doc_id, line_num, line, regex, pre_context.dup, [])
            hits << hit
            file_hits << hit
            if context_size > 0
              hits_needing_post_context << hit
            end
          end
          
          if pre_context.length == context_size
            pre_context.shift
          end
          pre_context << line
        end
        send_file_results(file_hits)
      end
      hits
    end
    
    def send_file_results(hits)
      if @on_file_results_block
        @on_file_results_block.call(hits)
      end
    end
    
    def results
      @results ||= generate_results
    end
    
    def bits
      query_string.
        gsub(/[^\w]/, " ").
        gsub("_", " ").
        split(/\s/).
        map {|b| b.strip}.
        reject {|b| b == "" or org.apache.lucene.analysis.standard.StandardAnalyzer::STOP_WORDS_SET.to_a.include?(b)}
    end
    
    def doc_ids
      @doc_ids ||= begin
        index = ProjectSearch.indexes[project.path].lucene_index
        doc_ids = nil
        bits.each do |bit|
          new_doc_ids = index.find(:contents => bit.downcase).map {|doc| doc.id }
          doc_ids = doc_ids ? (doc_ids & new_doc_ids) : new_doc_ids
        end
        doc_ids
      end
    end
  end
end

