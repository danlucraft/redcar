
describe "rspec describe blocks" do
  it "should run a spec in an it blockFAIL" do
    true.should be_true
  end

  it "should run a spec in an it block1" do
    true.should be_true
  end

  it "should run a spec in an it block2" do
    true.should be_true
  end

  describe "2nd level" do
    it "should run 2nd level it" do
      puts "SEE ME!!"
    end
  end

  describe "2nd level 2" do
    it "should run 2nd level 2 in it" do
      puts "SEE ME2!!"
    end
  end
end
