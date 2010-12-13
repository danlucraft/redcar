
class ProjectSearch
  class Hit
    attr_reader :file, :line_num, :line, :begin_ix, :end_ix
    
    def initialize(file, line_num, line, begin_ix, end_ix)
      @file, @line_num, @line, @begin_ix, @end_ix = file, line_num, line, begin_ix, end_ix
    end
    
    def text(start_with, end_with)
      "asdf"
    end
  end
end