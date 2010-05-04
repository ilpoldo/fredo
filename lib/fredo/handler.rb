module Fredo
  class Handler #:nodoc:
    
    attr_accessor :env, :request, :response, :params
    
    def call(env)
      @env      = env
      @request  = Rack::Request.new(env)
      @params   = @request.params
      @response = Response.new([],200,{})
      
      dispatch!
      
      respond!
    end
    
    # Dispatch a request with error handling.
    def dispatch!
      route!
    end
    
    def routes_for_host?
      Registry.routes[@request.request_method][@request.host]
    rescue
      false
    end
    
    def route!
      
      if routes = routes_for_host?
        path = URI.unescape(@request.path_info)
        routes.each do |pattern, keys, conditions, block|
          if match = pattern.match(path)
            values = match.captures.to_a
            params =
              if keys.any?
                keys.zip(values).inject({}) do |hash,(k,v)|
                  if k == :splat
                    (hash[k] ||= []) << v
                  else
                    hash[k.to_sym] = v
                  end
                  hash
                end
              elsif values.any?
                {'captures' => values}
              else
                {}
              end
            @params.merge!(params)
            
            Fredo.books << {:path => path,
                            :params => @params,
                            :method => @request.request_method,
                            :host => @request.host,
                            :body => @request.body.read}
            @request.body.rewind
            
            perform!(&block)
            return
          end
        end
        
      end
      
      raise NotFound
    end
    
    def handle_not_found!(boom)
      @env['fredo.error'] = boom
      @response.status    = 404
      @response.body      = ['<h1>Not Found</h1>']
    end
    
    def handle_exception!(boom)
      @env['fredo.error'] = boom
      @response.body   = ["<h1>You broke my heart Fredo!</h1><h5>Fredo raised an exception.</h5><tt>#{boom.inspect}</tt>"]
      @response.status = 500
      # raise Mixup.new("original error: #{boom.inspect}") if Fredo.allow_exceptions?
    end
    
    def perform!(&block)
      if block_given?
        @response['Content-Type']= 'text/html'
        
        res = instance_eval(&block)
        case
        when res.respond_to?(:to_str)
          @response.body = [res]
        when res.respond_to?(:to_ary)
          res = res.to_ary
          if Fixnum === res.first
            if res.length == 3
              @response.status, headers, body = res
              @response.body = body if body
              headers.each { |k, v| @response.headers[k] = v } if headers
            elsif res.length == 2
              @response.status = res.first
              @response.body   = res.last
            else
              raise TypeError, "#{res.inspect} not supported"
            end
          else
            @response.body = res
          end
        when res.respond_to?(:each)
          @response.body = res
        when (100...599) === res
          @response.status = res
        end
        
      end
    rescue ::Exception => boom
      handle_exception!(boom)
    end
    
    def respond!
      status, header, body = @response.finish
      [status, header, body]
    end
    
  end
end