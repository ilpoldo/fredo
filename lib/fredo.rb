require 'rubygems'
require 'uri'
require 'rack'

require 'fredo/ext/net_http'
require 'fredo/stub_socket'
require 'fredo/registry'
require 'fredo/handler'

module Fredo

  # Returns the version string for the Fredo you have loaded.
  VERSION = File.exist?('VERSION') ? File.read('VERSION') : ""

  # Resets Fredo's Registry. This will force all subsequent web requests to
  # behave as real requests.
  def self.clean_registry
    Registry.instance.clean_registry
  end
  
  # Registers get url that will make Fredo an OK response or the response generated 
  # in the block passed to get.
  def self.get(path, opts={}, &bk);    Registry.route 'GET',    path, opts, &bk end
  def self.put(path, opts={}, &bk);    Registry.route 'PUT',    path, opts, &bk end
  def self.post(path, opts={}, &bk);   Registry.route 'POST',   path, opts, &bk end
  def self.delete(path, opts={}, &bk); Registry.route 'DELETE', path, opts, &bk end
  def self.head(path, opts={}, &bk);   Registry.route 'HEAD',   path, opts, &bk end  
  
  # Enables or disables real HTTP connections for requests that don't match
  # registered URIs.
  #
  # If you set <tt>Fredo.allow_net_connect = false</tt> and subsequently try
  # to make a request to a URI you haven't registered with #register_uri, a
  # NetConnectNotAllowedError will be raised. This is handy when you want to
  # make sure your tests are self-contained, or want to catch the scenario
  # when a URI is changed in implementation code without a corresponding test
  # change.
  #
  # When <tt>Fredo.allow_net_connect = true</tt> (the default), requests to
  # URIs not stubbed with Fredo are passed through to Net::HTTP.
  def self.allow_net_connect=(allowed)
    @allow_net_connect = allowed
  end
  
  # Returns +true+ if requests to URIs not registered with Fredo are passed
  # through to Net::HTTP for normal processing (the default). Returns +false+
  # if an exception is raised for these requests.
  def self.allow_net_connect?
    @allow_net_connect || true
  end
  
  # This exception is raised if you set <tt>Fredo.allow_net_connect =
  # false</tt> and subsequently try to make a request to a URI you haven't
  # stubbed.
  class NetConnectNotAllowedError < StandardError
    def initialize(uri)
      super "Connection to #{uri} is disabled"
    end
  end
  
  # This exception is raised if something goes wrong on Fredo's end during
  # the test.
  class Mixup < Exception; end;
  
  # This exception is raised if Fredo can't match the request URI
  class NotFound < Exception; end;
  
  def self.call(env)
    Handler.new.call(env)
  end
  
  def self.forget
    Registry.clear
  end
end