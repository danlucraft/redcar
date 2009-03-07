
module FeatureHelpers
  def only(array)
    array.length.should == 1
    array.first
  end
end
