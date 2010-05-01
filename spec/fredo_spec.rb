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
        body
      end
      
      response = open('http://www.google.com')
      response.read.should eql(body)
      # response.header["Content-Type"].should eql("text/html")
    end
    
    it "can hijack a ssl resource" do
      body = "Don't trust this website."
      
      Fredo.get 'https://web-bank.com' do
        body
      end
      
      response = open('https://web-bank.com')
      response.read.should eql(body)
      # response.header["Content-Type"].should eql("text/html")
    end
    
    it "deals with post requests" do
      body = "This is the post body"
      
      Fredo.post 'http://postyourthoughts.com' do
        body
      end
      
      url = URI.parse 'http://postyourthoughts.com'
      http = Net::HTTP.new(url.host)
      http.post('/', 'query=foo', 'content-type' => 'text/plain').body.should eql(body)
    end
    
  end
  
  context "registry" do
    
    it "behaves" do
      Fredo.get 'http://google.com'
      Fredo::Registry.routes['GET'].should_not be_empty
    end
    
    it "it clears in every spec" do
      # Automate?
      Fredo.forget
      Fredo::Registry.routes.should be_empty
    end
    
  end
  
  context "tracks requests" do
    
    it "saves every request" do
      Fredo.get 'http://www.twitter.com/:name' do
        "It ain't #{params[:name]} talking"
      end
      
      response = open('http://www.twitter.com/sam')
      
      Fredo.books.last.host.should eql('www.twitter.com')
    end
    
  end
  
  context "parameters" do
    it "parses url parameters" do
      
      Fredo.get 'http://www.twitter.com/:name' do
        "It ain't #{params[:name]} talking"
      end
      
      response = open('http://www.twitter.com/sam')
      response.read.should include('It ain\'t sam')
    end
        
    it "parses query parameters" do
      
      Fredo.get 'http://www.google.com/search' do
        "You are looking for #{params['q']}"
      end
      
      response = open('http://www.google.com/search?q=happyness')
      response.read.should include('You are looking for happyness')
    end
    
    it "plays nice with regex" do
      Fredo.get 'http://www.google.com/*' do
        "Everything google!"
      end

      response = open('http://google.com/something')
      response.read.should include('Everything google!')
      
    end
  end
end
