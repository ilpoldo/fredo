module Fredo
  class Handler #:nodoc:
    
    attr_accessor :env, :request, :response, :params
    
    def call(env)
      @env      = env
      @request  = Rack::Request.new(env)
      @params   = @request.params
      @response = Rack::Response.new([],200,{})
      
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
        status, header, body = instance_eval(&block)
        @response.status    = status
        @response.write body
      else
        @response.body   = ["OK"]
        @response.status = 200
      end
    rescue ::Exception => boom
      handle_exception!(boom)
    end
    
    def respond!
      # [@response.headers, @response.body]
      @response.finish
      [@response.status, @response.header, @response.body.join("\n")]
    end
    
  end
end