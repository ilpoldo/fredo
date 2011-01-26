require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'faraday'

describe Fredo do
  
  
  context "request handling" do
    
    
    
    it "intercepts faraday's requests" do
      body = "Today ain't your lucky day, kid."
      
      Fredo.get('http://www.google.com') {body}
      
      response = Faraday.get 'http://www.google.com/'
      
      response.body.should eql(body)
    end
  end
  
end