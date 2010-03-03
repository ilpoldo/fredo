$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'fredo'
require 'spec'
require 'spec/autorun'
require 'open-uri'

Spec::Runner.configure do |config|
  
end
