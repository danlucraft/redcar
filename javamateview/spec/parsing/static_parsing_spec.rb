
require 'spec/spec_helper'

describe JavaMateView do
  before(:each) do
    $display ||= Swt::Widgets::Display.new
    @shell = Swt::Widgets::Shell.new(@display)
    @mt = JavaMateView::MateText.new(@shell, false)
    @st = @mt.get_text_widget
  end
  
  after(:each) do
    @mt.get_text_widget.dispose
    @shell.dispose
    $display.dispose
  end
  
  describe "when parsing Ruby from scratch" do
    before(:each) do
      @mt.set_grammar_by_name("Ruby")
    end
  
    it "does something" do
      @st.get_line_count.should == 1
    end
  
    it "should have a blank Ruby scope tree" do
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,0) open
END
    end
  
    it "parses flat SinglePatterns" do
      @st.text = "1 + 2 + Redcar"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,14) open
  + constant.numeric.ruby (0,0)-(0,1) closed
  + keyword.operator.arithmetic.ruby (0,2)-(0,3) closed
  + constant.numeric.ruby (0,4)-(0,5) closed
  + keyword.operator.arithmetic.ruby (0,6)-(0,7) closed
  + variable.other.constant.ruby (0,8)-(0,14) closed
END
    end
  
    it "parses flat SinglePatterns on multiple lines" do
      @st.text = "1 + \n3 + Redcar"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(1,10) open
  + constant.numeric.ruby (0,0)-(0,1) closed
  + keyword.operator.arithmetic.ruby (0,2)-(0,3) closed
  + constant.numeric.ruby (1,0)-(1,1) closed
  + keyword.operator.arithmetic.ruby (1,2)-(1,3) closed
  + variable.other.constant.ruby (1,4)-(1,10) closed
END
    end
  
    it "arranges SinglePattern captures into trees" do
      @st.text = "class Red < Car"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,15) open
  + meta.class.ruby (0,0)-(0,15) closed
    c keyword.control.class.ruby (0,0)-(0,5) closed
    c entity.name.type.class.ruby (0,6)-(0,15) closed
      c entity.other.inherited-class.ruby (0,9)-(0,15) closed
        c punctuation.separator.inheritance.ruby (0,10)-(0,11) closed
END
    end
  
    it "opens DoublePatterns" do
      @st.text = "\"asdf"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,5) open
  + string.quoted.double.ruby (0,0)-(0,5) open
    c punctuation.definition.string.begin.ruby (0,0)-(0,1) closed
END
    end
    
    it "closes DoublePatterns" do
      @st.text = "\"asdf\""
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,6) open
  + string.quoted.double.ruby (0,0)-(0,6) closed
    c punctuation.definition.string.begin.ruby (0,0)-(0,1) closed
    c punctuation.definition.string.end.ruby (0,5)-(0,6) closed
END
    end
  
    it "knows content_names of DoublePatterns" do
      @st.text = "def foo(a, b)"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,13) open
  + meta.function.method.with-arguments.ruby variable.parameter.function.ruby (0,0)-(0,13) closed
    c keyword.control.def.ruby (0,0)-(0,3) closed
    c entity.name.function.ruby (0,4)-(0,7) closed
    c punctuation.definition.parameters.ruby (0,7)-(0,8) closed
    + punctuation.separator.object.ruby (0,9)-(0,10) closed
    c punctuation.definition.parameters.ruby (0,12)-(0,13) closed
END
    end
  
    it "creates scopes as children of DoublePatterns" do
      @st.text = "\"laura\\nroslin\""
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,15) open
  + string.quoted.double.ruby (0,0)-(0,15) closed
    c punctuation.definition.string.begin.ruby (0,0)-(0,1) closed
    + constant.character.escape.ruby (0,6)-(0,8) closed
    c punctuation.definition.string.end.ruby (0,14)-(0,15) closed
END
    end
  
    it "creates closing regexes correctly" do
      @st.text = "foo=\<\<END\nstring\nEND"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(2,3) open
  + string.unquoted.heredoc.ruby (0,3)-(2,3) closed
    c punctuation.definition.string.begin.ruby (0,3)-(0,9) closed
    c punctuation.definition.string.end.ruby (2,0)-(2,3) closed
END
    end

    it "creates multiple levels of scopes" do
      @st.text = "\"william \#{:joseph} adama\""
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(0,26) open
  + string.quoted.double.ruby (0,0)-(0,26) closed
    c punctuation.definition.string.begin.ruby (0,0)-(0,1) closed
    + source.ruby.embedded.source (0,9)-(0,19) closed
      c punctuation.section.embedded.ruby (0,9)-(0,11) closed
      + constant.other.symbol.ruby (0,11)-(0,18) closed
        c punctuation.definition.constant.ruby (0,11)-(0,12) closed
      c punctuation.section.embedded.ruby (0,18)-(0,19) closed
    c punctuation.definition.string.end.ruby (0,25)-(0,26) closed
END
    end
  
    it "parses some Ruby correctly" do
      @st.text = <<END
class Red < Car
  attr :foo
  Dir["*"].each do |fn|
    p fn
  end
end
END
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(6,0) open
  + meta.class.ruby (0,0)-(0,15) closed
    c keyword.control.class.ruby (0,0)-(0,5) closed
    c entity.name.type.class.ruby (0,6)-(0,15) closed
      c entity.other.inherited-class.ruby (0,9)-(0,15) closed
        c punctuation.separator.inheritance.ruby (0,10)-(0,11) closed
  + keyword.other.special-method.ruby (1,2)-(1,6) closed
  + constant.other.symbol.ruby (1,7)-(1,11) closed
    c punctuation.definition.constant.ruby (1,7)-(1,8) closed
  + support.class.ruby (2,2)-(2,5) closed
  + punctuation.section.array.ruby (2,5)-(2,6) closed
  + string.quoted.double.ruby (2,6)-(2,9) closed
    c punctuation.definition.string.begin.ruby (2,6)-(2,7) closed
    c punctuation.definition.string.end.ruby (2,8)-(2,9) closed
  + punctuation.section.array.ruby (2,9)-(2,10) closed
  + punctuation.separator.method.ruby (2,10)-(2,11) closed
  + keyword.control.start-block.ruby (2,16)-(2,19) closed
  + [noname] (2,19)-(2,23) closed
    c punctuation.separator.variable.ruby (2,19)-(2,20) closed
    + variable.other.block.ruby (2,20)-(2,22) closed
    c punctuation.separator.variable.ruby (2,22)-(2,23) closed
  + keyword.control.ruby (4,2)-(4,5) closed
  + keyword.control.ruby (5,0)-(5,3) closed
END
    end

    it "embeds HTML in Ruby" do
      @st.text = <<END
foo=<<-HTML
<p>FOO</p>
HTML
END
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(3,0) open
  + keyword.operator.assignment.ruby (0,3)-(0,4) closed
  + string.unquoted.embedded.html.ruby text.html.embedded.ruby (0,4)-(2,4) closed
    c punctuation.definition.string.begin.ruby (0,4)-(0,11) closed
    + meta.tag.block.any.html (1,0)-(1,3) closed
      c punctuation.definition.tag.begin.html (1,0)-(1,1) closed
      c entity.name.tag.block.any.html (1,1)-(1,2) closed
      c punctuation.definition.tag.end.html (1,2)-(1,3) closed
    + meta.tag.block.any.html (1,6)-(1,10) closed
      c punctuation.definition.tag.begin.html (1,6)-(1,8) closed
      c entity.name.tag.block.any.html (1,8)-(1,9) closed
      c punctuation.definition.tag.end.html (1,9)-(1,10) closed
    c punctuation.definition.string.end.ruby (2,0)-(2,4) closed
END
    end


    it "embeds CSS in HTML in Ruby" do
      @st.text = <<END
foo=<<-HTML
<style>
  .foo {

  }
</style>
HTML
END
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.ruby (0,0)-(7,0) open
  + keyword.operator.assignment.ruby (0,3)-(0,4) closed
  + string.unquoted.embedded.html.ruby text.html.embedded.ruby (0,4)-(6,4) closed
    c punctuation.definition.string.begin.ruby (0,4)-(0,11) closed
    + source.css.embedded.html (1,0)-(5,8) closed
      c punctuation.definition.tag.html (1,0)-(1,1) closed
      c entity.name.tag.style.html (1,1)-(1,6) closed
      + [noname] (1,6)-(5,0) closed
        c punctuation.definition.tag.html (1,6)-(1,7) closed
        + meta.selector.css (2,0)-(2,7) closed
          + entity.other.attribute-name.class.css (2,2)-(2,6) closed
            c punctuation.definition.entity.css (2,2)-(2,3) closed
        + meta.property-list.css (2,7)-(4,3) closed
          c punctuation.section.property-list.css (2,7)-(2,8) closed
          c punctuation.section.property-list.css (4,2)-(4,3) closed
      c punctuation.definition.tag.html (5,0)-(5,2) closed
      c entity.name.tag.style.html (5,2)-(5,7) closed
      c punctuation.definition.tag.html (5,7)-(5,8) closed
    c punctuation.definition.string.end.ruby (6,0)-(6,4) closed
END
    end
  
    it "should do YAML" do
      @mt.set_grammar_by_name("YAML")
      @st.text = <<YAML
--- !ruby/object:Free
YAML
    end

    it "should parse this Python without falling off the end of the line" do
      source = <<-PYTHON
      __gsignals__ =  { 
        "completed": (
            gobject.SIGNAL_RUN_LAST, gobject.TYPE_NONE, [])
      }
    PYTHON
      @mt.set_grammar_by_name("Python")
      @st.text = source
    end


    it "should parse this Ruby without dying" do
      source = <<-RUBY
"–",
    RUBY
      @mt.set_grammar_by_name("Ruby")
      @st.text = source
    end

    it "should parse these C comments correctly" do
      source = <<-TEXT
/* H
*/
Gtk gtk_ (Gtk* self) {
    TEXT
      @mt.set_grammar_by_name("C")
      @st.text = source
      @mt.parser.root.pretty(0).should_not include("invalid.illegal")
    end

    it "should parse this PHP without dying" do
      source = <<-PHP
<?php
/**
*
*/
class ClassName extends AnotherClass
{
    PHP
      @mt.set_grammar_by_name("PHP").should be_true
      @st.text = source
    end

    it "should not have any problem with Japanese UTF-8 characters" do
      @mt.set_grammar_by_name("Plain Text")
      @st.text = "日本"
    end
  end

  describe "performance" do
    before do
      @mt.set_grammar_by_name("Ruby")
    end
    
    it "should parse a long line in a reasonable time" do
      s = Time.now
      @st.text = "() "*500
      e = Time.now
      (e - s).should < 2
    end
    
    it "should parse a big file in a reasonable time" do
      s = Time.now
      @st.text = File.read("/Users/danlucraft/Redcar/redcar/plugins/redcar/redcar.rb")
      e = Time.now
      (e - s).should < 2
    end
  end

  describe "when parsing Perl from scratch" do
    before(:each) do
      @mt.set_grammar_by_name("Perl").should be_true
    end
  
    it "Parses simple perl comment line" do
      source = <<-Perl
# Comment line with enter
Perl
      @st.text = source
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.perl (0,0)-(1,0) open
  + meta.comment.full-line.perl (0,0)-(0,25) closed
    c comment.line.number-sign.perl (0,0)-(0,25) closed
      c punctuation.definition.comment.perl (0,0)-(0,1) closed
END
    end
  
    it "Parses single perl declaration" do
      @st.text = "my $a;"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.perl (0,0)-(0,6) open
  + storage.modifier.perl (0,0)-(0,2) closed
  + variable.other.predefined.perl (0,3)-(0,5) closed
    c punctuation.definition.variable.perl (0,3)-(0,4) closed
END
    end

    it "Parses some Perl code correctly" do
      @st.text = <<END
sub RedCar {
 my $car = shift;
 my $color = "red";
 my $i = 1;

 while ( $i == 1 ) {
   print "My car is $car, its color is $color\n"; 
 }
}
END
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.perl (0,0)-(10,0) open
  + meta.function.perl (0,0)-(0,11) closed
    c storage.type.sub.perl (0,0)-(0,3) closed
    c entity.name.function.perl (0,4)-(0,10) closed
  + storage.modifier.perl (1,1)-(1,3) closed
  + variable.other.readwrite.global.perl (1,4)-(1,8) closed
    c punctuation.definition.variable.perl (1,4)-(1,5) closed
  + support.function.perl (1,11)-(1,16) closed
  + storage.modifier.perl (2,1)-(2,3) closed
  + variable.other.readwrite.global.perl (2,4)-(2,10) closed
    c punctuation.definition.variable.perl (2,4)-(2,5) closed
  + string.quoted.double.perl (2,13)-(2,18) closed
    c punctuation.definition.string.begin.perl (2,13)-(2,14) closed
    c punctuation.definition.string.end.perl (2,17)-(2,18) closed
  + storage.modifier.perl (3,1)-(3,3) closed
  + variable.other.readwrite.global.perl (3,4)-(3,6) closed
    c punctuation.definition.variable.perl (3,4)-(3,5) closed
  + keyword.control.perl (5,1)-(5,6) closed
  + variable.other.readwrite.global.perl (5,9)-(5,11) closed
    c punctuation.definition.variable.perl (5,9)-(5,10) closed
  + support.function.perl (6,3)-(6,8) closed
  + string.quoted.double.perl (6,9)-(7,1) closed
    c punctuation.definition.string.begin.perl (6,9)-(6,10) closed
    + variable.other.readwrite.global.perl (6,20)-(6,24) closed
      c punctuation.definition.variable.perl (6,20)-(6,21) closed
    + variable.other.readwrite.global.perl (6,39)-(6,45) closed
      c punctuation.definition.variable.perl (6,39)-(6,40) closed
    c punctuation.definition.string.end.perl (7,0)-(7,1) closed
END
    end
  end

  describe "When parsing HTML:" do

    before do
      @mt.set_grammar_by_name("HTML")
    end
    
    it "should parse an † without blowing up" do
      @st.text = "<h1 class=\"†\">\n"
    end

    it "Test an embedded php string which starts at the beginning of the line" do
      @st.text = "<? print(\"Asdf\") ?>"
      @mt.parser.root.pretty(0).should == (t=<<END)
+ text.html.basic (0,0)-(0,19) open
  + [noname] (0,0)-(0,19) open
    + [noname] (0,0)-(0,19) closed
      c punctuation.whitespace.embedded.leading.php (0,0)-(0,0) closed
      + source.php.embedded.block.html (0,0)-(0,19) closed
        c punctuation.section.embedded.begin.php (0,0)-(0,2) closed
        + support.function.construct.php (0,3)-(0,8) closed
        + string.quoted.double.php meta.string-contents.quoted.double.php (0,9)-(0,15) closed
          c punctuation.definition.string.begin.php (0,9)-(0,10) closed
          c punctuation.definition.string.end.php (0,14)-(0,15) closed
        c punctuation.section.embedded.end.php (0,17)-(0,19) closed
          c source.php (0,17)-(0,18) closed
      c punctuation.whitespace.embedded.trailing.php (0,19)-(0,19) closed
END
    end
  end
  
  describe "When parsing Java" do
    before do
      @mt.set_grammar_by_name("Java")
    end
    
    it "should parse constants correctly" do
      @st.text = <<JAVA
Level.SEVERE
JAVA
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.java (0,0)-(1,0) open
  + storage.type.java (0,0)-(0,5) closed
  + constant.other.java (0,5)-(0,12) closed
    c keyword.operator.dereference.java (0,5)-(0,6) closed
END
    end
    
    it "should not have a weird comment bug" do
      @st.text = <<JAVA
public class Foo {
	public int nonn() {
//		}
	}
}

JAVA
      @mt.parser.root.pretty(0).should == (t=<<END)
+ source.java (0,0)-(6,0) open
  + meta.class.java (0,0)-(4,1) closed
    + [noname] (0,0)-(0,6) closed
      c storage.modifier.java (0,0)-(0,6) closed
    + meta.class.identifier.java (0,7)-(0,16) closed
      c storage.modifier.java (0,7)-(0,12) closed
      c entity.name.type.class.java (0,13)-(0,16) closed
    + meta.class.body.java (0,17)-(4,0) closed
      + meta.method.java (1,1)-(3,2) closed
        + [noname] (1,1)-(1,7) closed
          c storage.modifier.java (1,1)-(1,7) closed
        + meta.method.return-type.java (1,8)-(1,12) closed
          + storage.type.primitive.array.java (1,8)-(1,11) closed
        + meta.method.identifier.java (1,12)-(1,18) closed
          c entity.name.function.java (1,12)-(1,16) closed
        + meta.method.body.java (1,19)-(3,1) closed
          + [noname] (2,0)-(2,5) closed
            c comment.line.double-slash.java (2,0)-(2,5) closed
              c punctuation.definition.comment.java (2,0)-(2,2) closed
    c punctuation.section.class.end.java (4,0)-(4,1) closed
END
    end
  end
  
  describe "when parsing JavaScript" do
    before do
      @mt.set_grammar_by_name("JavaScript")
    end
    
    it "should parse the following line and not hang" do
      @st.text = <<JAVASCRIPT
C=z&&z.events;if(z&&C){if(b&&b.type){d=b.handler;b=b.type}if(!b||typeof b==="string"&&b.charAt(0)==="."){b=b||"";for(e in C)c.event.remove(a,e+b)}else{for(b=b.split(" ");e=b[j++];){n=e;i=e.indexOf(".")<0;o=[];if(!i){o=e.split(".");e=o.shift();k=new RegExp("(^|\\.)"+c.map(o.slice(0).sort(),db).join("\\.(?:.*\\.)?")+"(\\.|$)")}if(r=C[e])if(d){n=c.event.special[e]||{};for(B=f||0;B<r.length;B++){u=r[B];if(d.guid===u.guid){if(i||k.test(u.namespace)){f==null&&r.splice(B--,1);n.remove&&n.remove.call(a,u)}if(f!=
JAVASCRIPT
      @mt.parser.root.pretty(0)
    end
  end
end



