
module FeatureHelpers
  STRING_RE = /"((?:[^"]|\\")+)"/
  
  def only(array)
    array.length.should == 1
    array.first
  end
end
