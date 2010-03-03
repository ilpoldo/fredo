# File lib/rack/handler/mongrel.rb
def process(request, response)
  env = {}.replace(request.params)
  env.delete "HTTP_CONTENT_TYPE"
  env.delete "HTTP_CONTENT_LENGTH"

  env["SCRIPT_NAME"] = ""  if env["SCRIPT_NAME"] == "/"

  env.update({"rack.version" => [0,1],
               "rack.input" => request.body || StringIO.new(""),
               "rack.errors" => $stderr,

               "rack.multithread" => true,
               "rack.multiprocess" => false, # ???
               "rack.run_once" => false,

               "rack.url_scheme" => "http",
             })
  env["QUERY_STRING"] ||= ""
  env.delete "PATH_INFO"  if env["PATH_INFO"] == ""

  status, headers, body = @app.call(env)

  begin
    response.status = status.to_i
    response.send_status(nil)

    headers.each { |k, vs|
      vs.split("\n").each { |v|
        response.header[k] = v
      }
    }
    response.send_header

    body.each { |part|
      response.write part
      response.socket.flush
    }
  ensure
    body.close  if body.respond_to? :close
  end
end
