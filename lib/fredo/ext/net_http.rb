require 'net/http'
require 'net/https'
require 'stringio'

module Net  #:nodoc: all

  class BufferedIO
    def initialize_with_fredo(io, debug_output = nil)
      @read_timeout = 60
      @rbuf = ''
      @debug_output = debug_output

      @io = case io
      when Socket, OpenSSL::SSL::SSLSocket, IO
        io
      when String
        if !io.include?("\0") && File.exists?(io) && !File.directory?(io)
          File.open(io, "r")
        else
          StringIO.new(io)
        end
      end
      raise "Unable to create local socket" unless @io
    end
    alias_method :initialize_without_fredo, :initialize
    alias_method :initialize, :initialize_with_fredo
  end

  class HTTP
    # class << self
    #   def socket_type_with_fredo
    #     Fredo::StubSocket
    #   end
    #   alias_method :socket_type_without_fredo, :socket_type
    #   alias_method :socket_type, :socket_type_with_fredo
    # end

    def request_with_fredo(request, body = nil, &block)
      request_body = body
      
      case request_body
      when nil    then body = StringIO.new
      when String then body = StringIO.new(body)
      when File then body
      else
        body = StringIO.new(body.to_s)
      end
        
      uri = URI.parse(request.path)
      protocol = use_ssl? ? "https" : "http"
      full_path = "#{protocol}://#{self.address}:#{self.port}#{request.path}"
      
      rack_env ={'REQUEST_METHOD'    => request.method,
                 'SCRIPT_NAME'       => '',
                 'PATH_INFO'         => uri.path,
                 'QUERY_STRING'      => (uri.query || ''),
                 'SERVER_NAME'       => self.address,
                 'SERVER_PORT'       => self.port,
                 'rack.version'      => [1,1],
                 'rack.url_scheme'   => protocol,
                 'rack.input'        => body,
                 'rack.errors'       => $stderr,
                 'rack.multithread'  => true,
                 'rack.multiprocess' => true,
                 'rack.run_once'     => false}

      # @socket = Net::HTTP.socket_type.new
      # Perform the request
      status, header, body = Fredo.call(rack_env)
      
      response = Net::HTTPResponse.send(:response_class, "#{status}").new("1.0", "#{status}", body)
      response.instance_variable_set(:@body, body)
      header.each { |name, value| response[name] = value }
      response.instance_variable_set(:@read, true)
      
      def response.read_body(*args, &block)
        yield @body.join("\n") if block_given?
        @body.join("\n")
      end

      yield response if block_given?
      response
      
    rescue Fredo::NotFound
      
      raise Fredo::NetConnectNotAllowedError.new(full_path) unless Fredo.allow_net_connect?
      connect_without_fredo
      return request_without_fredo(request, request_body, &block)
      
    end
    alias_method :request_without_fredo, :request
    alias_method :request, :request_with_fredo


    def connect_with_fredo
      unless @@alredy_checked_for_net_http_replacement_libs ||= false
        # Fredo::Utility.puts_warning_for_net_http_replacement_libs_if_needed
        @@alredy_checked_for_net_http_replacement_libs = true
      end
      nil
    end
    alias_method :connect_without_fredo, :connect
    alias_method :connect, :connect_with_fredo
  end

end
