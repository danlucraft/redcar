
class ProjectSearch
  class Hit
    attr_reader :file, :line_num, :pre_context, :post_context
    
    def initialize(file, line_num, line, regex, 
        pre_context, post_context)
      @file, @line_num, @line, @regex = file, line_num, line, regex
      @pre_context = pre_context
      @post_context = post_context
    end
    
    def line(start_with=nil, end_with=nil)
      @line.gsub(@regex) { start_with.to_s + $& + end_with.to_s }
    end
  end
end