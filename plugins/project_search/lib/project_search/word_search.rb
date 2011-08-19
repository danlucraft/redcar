
class ProjectSearch
  class WordSearch
    java_import org.apache.lucene.util.Version
    java_import org.apache.lucene.analysis.standard.StandardAnalyzer
    java_import org.apache.lucene.queryParser.QueryParser

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
        # Replace Lucene wildcards with non-greedy Ruby regex equivalents
        # TODO: determine best (expected?) way of handling phrases
        regexp_text = regexp_text.gsub(/\\\s+or\\\s+/i,"|").gsub('\\*','.*?').gsub('\\?','.').gsub(/\\\s+/,".*?")
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
          pre_context << line
          if pre_context.length > context_size
            pre_context.shift
          end
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

    def formatted_query
      parser = QueryParser.new(
        Version::LUCENE_29,
        "contents",
        StandardAnalyzer.new(Version::LUCENE_29)
      )
      parser.parse(query_string).to_s
    end

    def doc_ids
      @doc_ids ||= begin
        index = ProjectSearch.indexes[project.path].lucene_index
        doc_ids = nil
        doc_ids = index.find(formatted_query).map {|doc| doc.id}
        doc_ids.reject {|doc_id| Redcar::Project::FileList.hide_file_path?(doc_id) }
      end
    end
  
    def ignore_regexes
      self.class.shared_storage['ignored_file_patterns']
    end

    def ignore_file?(filename)
      if self.class.storage['ignore_file_patterns']
        ignore_regexes.any? {|re| re =~ filename }
      end
    end

    def inspect
      if @results
        "<ProjectSearch::WordSearch #{project.path} \"#{query_string}\" #{@results.length} hits>"
      else
        "<ProjectSearch::WordSearch #{project.path} \"#{query_string}\" ...>"
      end
    end
  end
end

