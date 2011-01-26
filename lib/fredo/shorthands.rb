module Fredo
  module Shorthands
    
    def oauth(provider, credentials)
     
     case provider
     when 'twitter'
       #Application request token
       post 'https://api.twitter.com/oauth/request_token' do
         [
           200, {:oauth_token_secret => 1234,
                 :oauth_token => 'abc123',
                 :oauth_callback_confirmed => true},
           []
         ]
       end
       
       # User performs verification
       get 'https://api.twitter.com/oauth/authorize' do
         redirect_url = URI.parse params['redirect_uri']
         redirect_url.query = querify :oauth_token => 12345, :oauth_verifier => 'abc123'
         [ 302, {'Location'=> redirect_url.to_s }, [] ]        
       end
       
       # Twitter sends back the access token as an url encoded reply?
       post 'https://api.twitter.com/oauth/access_token' do
         [
           200, {},
           querify(:oauth_token_secret => 1234, :oauth_token => 'abc123', :user_id => 1234, :screen_name => 'john.smith')
         ]
       end
       
       get('https://api.twitter.com/account/verify_credentials.json'){[200, {}, credentials.to_json]}
       
     when 'facebook'
       
       # User authorization
       get 'https://graph.facebook.com/oauth/authorize' do
         redirect_url = URI.parse params['redirect_uri']
         redirect_url.query = querify :code => 12345
         [ 302, {'Location'=> redirect_url.to_s }, [] ]
       end
       
       # Fetching the token
       get 'https://graph.facebook.com/oauth/access_token'  do
         [
           200, {'Content-Type' => 'application/json' }, 
           {:access_token => 12345, :expires => 10.days.from_now.to_i}.to_json
         ]
       end
       
       # fetching credentials
       get 'https://graph.facebook.com/me' do
         [
           200, {'Content-Type' => 'application/json' }, 
           credentials.to_json
         ]
       end
     end
     
    end
    
  private
    
    def queryfy(hash)
      hash.map {|k,v| "%s=%s" % [URI.encode(k.to_s), URI.encode(v.to_s)]}.join('&')
    end
    
  end
end