require File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper")

class Redcar::Project
  describe Adapters::RemoteProtocols::FTP do
    let(:conn) { double('connection') }
    subject do
      Adapters::RemoteProtocols::FTP.new('server', 'user', 'secret', '/creation')
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
        Adapters::RemoteProtocols::FTP.new('server', 'user', 'secret', '/creation').tap do |ftp|
          ftp.stub!(:connection).and_return(conn)
        end
      end
      
      describe '#dir_listing' do
        it "parses the response of the FTP LIST command" do
          parsed1 = double('parsed entry 1')
          parsed1.should_receive(:basename).and_return('first_file.txt')
          parsed1.should_receive(:dir?).and_return(false)
          parsed1.should_receive(:file?).and_return(true)

          parsed2 = double('parsed entry 2')
          parsed2.should_receive(:basename).and_return('scripts')
          parsed2.should_receive(:dir?).and_return(true)
          parsed2.should_receive(:file?).and_return(false)

          Net::FTP::List.should_receive(:parse).and_return(parsed1, parsed2)

          conn.should_receive(:list).with('/creation').and_yield('first entry').and_yield('second entry')
          subject.dir_listing('/creation').should == [
            "file|first_file.txt", "dir|scripts"
          ]
        end
      end
    end
  end
end