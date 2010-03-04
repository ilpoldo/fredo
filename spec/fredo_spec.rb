require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Fredo do
  context "initialization" do
    
    it "loads"
    
    it "hijacks Net::Http"
    
  end

  context "request handling" do
    
    it "falls back to normal behaviour" do
      response = open('http://www.google.com')
      response.status.first.should eql('200')
    end
    
    it "can hijack a request and return a value"
    
    it "can prevent external resources to be called"
    
    it "can hijack a get request" do
      body = "Today ain't your lucky day, kid."
      
      Fredo.get 'http://www.google.com' do
        [200, {"Content-Type" => "text/html"}, body]
      end
      
      response = open('http://www.google.com')
      response.read.should eql(body)
      # response.header["Content-Type"].should eql("text/html")
    end
  end
  
  context "registry" do
    
    it "behaves" do
      Fredo.get 'http://google.com'
      Fredo::Registry.routes['GET'].should_not be_empty
    end
    
    it "is clears in every spec" do
      # Automate?
      Fredo.forget
      Fredo::Registry.routes.should be_empty
    end
    
  end
  
  context "parameters" do
    it "parses url parameters" do
      
      Fredo.get 'http://www.twitter.com/:name' do
        [200, {"Content-Type" => "text/html"}, "It ain't #{params[:name]} talking"]
      end
      
      response = open('http://www.twitter.com/sam')
      response.read.should include('It ain\'t sam')
    end
    
    it "plays nice with regex" do
      Fredo.get 'http://www.google.com/*' do
        [200, {"Content-Type" => "text/html"}, "Everything google!"]
      end

      response = open('http://google.com/something')
      response.read.should include('Everything google!')
      
    end
  end
end
