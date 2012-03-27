require File.dirname(__FILE__) + "/../../spec/spec_helper"

describe Onig::Match do
  it "is returned from a regex search" do
    rx = Onig::Rx.createRx("fo?o")
    rx.search("foo").should be_an_instance_of(Onig::Match)
  end
  
  def search(pattern, string)
    Onig::Rx.createRx(pattern).search(string)
  end
  
  it "tells you how many captures it has" do
    search("foo", "foo").num_captures.should == 1
    search("f(oo)", "foo").num_captures.should == 2
    search("(f)(oo)", "foo").num_captures.should == 3
    search("(f)(o)(o)", "foo").num_captures.should == 4
  end
  
  it "returns the start offsets of the captures" do
    search("(f)(oo)", "foo").get_capture(0).start.should == 0
    search("(f)(oo)", "foo").get_capture(1).start.should == 0
    search("(f)(oo)", "foo").get_capture(2).start.should == 1
  end
  
  it "returns the end offsets of the captures" do
    search("(f)(oo)", "foo").get_capture(0).end.should == 3
    search("(f)(oo)", "foo").get_capture(1).end.should == 1
    search("(f)(oo)", "foo").get_capture(2).end.should == 3
  end
  
  it "returns character offsets" do
    search("(f)(.o)", "f†o").get_capture(0).end.should == 3
    search("(f)(.o)", "f†o").get_capture(1).end.should == 1
    search("(f)(.o)", "f†o").get_capture(2).end.should == 3
  end

  it "but you can get the byte offsets if you want them" do
    search("(f)(.o)", "f†o").get_byte_capture(0).end.should == 5
    search("(f)(.o)", "f†o").get_byte_capture(1).end.should == 1
    search("(f)(.o)", "f†o").get_byte_capture(2).end.should == 5
  end

  it "matches a complex regex and returns character offsets" do
    pattern = "\\b(0[xX]\\h(?>_?\\h)*|\\d(?>_?\\d)*(\\.(?![^[:space:][:digit:]])(?>_?\\d)*)?([eE][-+]?\\d(?>_?\\d)*)?|0[bB][01]+)\\b"
    match = search(pattern, "1 + 2 + 'Redcar'")
    match.get_capture(0).start.should == 0
    match.get_capture(0).end.should == 1
  end
end