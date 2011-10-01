require "spec_helper"

describe Redcar::EditView::AlignAssignmentCommand do
  
  def check(starting, expected)
    Redcar::EditView::AlignAssignmentCommand.align(starting.chomp).should == (expected).chomp
  end
  
  it "should align simple assignments" do
    check(<<-END, <<-END2)
a = 4
bc = 5
d = 123
END
a  = 4
bc = 5
d  = 123
END2
  end
  
  it "should align simple indented assignments" do
    check(<<-END, <<-END2)
  a = 4
  bc = 5
  d = 123
END
  a  = 4
  bc = 5
  d  = 123
END2
  end
  
  it "should align rows that have empty lines" do
    check(<<-END, <<-END2)
      a = 1

      ab = 123
END
      a  = 1

      ab = 123
END2
  end
  
  it "should align the right hand side" do
    check(<<-END, <<-END2)
      a = 1
      bb =     2
      ccc = 3
END
      a   = 1
      bb  = 2
      ccc = 3
END2
  end
  
  it "should align different length operators" do
    check(<<-END, <<-END2)
      Integer === 1
      two =~ /2/
      @three||= 3333
      bits &= 0b101010
    END
      Integer === 1
      two      =~ /2/
      @three  ||= 3333
      bits     &= 0b101010
    END2
  end
  
  it "should align hashrockets" do
    check(<<-END, <<-END2)
      {:one => 1,
      :two => 22,
      :threee => 333}
    END
      {:one   => 1,
      :two    => 22,
      :threee => 333}
    END2
  end
end

