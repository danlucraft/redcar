require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

require 'net/ssh'
require 'net/ftp'
require 'net/ftp/list'

class Redcar::Project
  describe Adapters::RemoteProtocols::FTP do
    let(:conn) { double('connection') }
    subject do
      Adapters::RemoteProtocols::FTP.new('server', 'user', 'secret', [])
    end
    
    before(:each) do
      Net::FTP.stub!(:open).with('server', 'user', 'secret')
    end
    
    describe '#connection' do
      it "instantiates a new Net::FTP connection" do
        Net::FTP.should_receive(:open).with('server', 'user', 'secret')
        subject.connection
      end
    end
    
    describe 'methods' do
      subject do
        Adapters::RemoteProtocols::FTP.new('server', 'user', 'secret', []).tap do |ftp|
          ftp.stub!(:connection).and_return(conn)
        end
      end
      
      describe '#mtime' do
        it "does something" do
          mtime1 = stub('mtime1')
          mtime2 = stub('mtime2')
          subject.stub!(:fetch).with("/creation").and_return([
            { :fullname => '/creation/first_file.txt', :name => 'first_file.txt', :type => :file, :mtime => mtime1 },
            { :fullname => '/creation/scripts',        :name => 'scripts',        :type => :dir , :mtime => mtime2 }
          ])
          subject.mtime("/creation/first_file.txt").should == mtime1
          subject.mtime("/creation/scripts").should == mtime2
        end
      end

      describe '#dir_listing' do
        it "parses the response of the FTP LIST command" do
          parsed1 = double('parsed entry 1')
          parsed1.should_receive(:basename).and_return('first_file.txt')
          parsed1.should_receive(:dir?).and_return(false)
          parsed1.should_receive(:file?).and_return(true)
          parsed1.should_receive(:mtime).and_return(time1=Time.now)
          
          parsed2 = double('parsed entry 2')
          parsed2.should_receive(:basename).and_return('scripts')
          parsed2.should_receive(:dir?).and_return(true)
          parsed2.should_receive(:file?).and_return(false)
          parsed2.should_receive(:mtime).and_return(time2=Time.now)

          Net::FTP::List.should_receive(:parse).and_return(parsed1, parsed2)

          conn.should_receive(:list).with('/creation').and_yield('first entry').and_yield('second entry')
          result = subject.dir_listing('/creation')
          result[0][:name].should == 'first_file.txt'
          result[1][:name].should == 'scripts'

          result[0][:type].should == 'file'
          result[1][:type].should == 'dir'

          result[0][:mtime].should == time1
          result[1][:mtime].should == time2
        end
      end
    end
  end
end