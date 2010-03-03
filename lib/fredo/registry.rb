module Fredo
  class Registry #:nodoc:
    
    def self.route(verb, uri, options={}, &block)
      uri = URI.parse(uri)
      uri.path = '/' if uri.path.empty? 
      pattern, keys = compile(uri.path)

      @routes ||={}
      @routes[verb] ||= {}
      (@routes[verb][uri.host] ||= []).
        push([pattern, keys, options, block]).last
    end
    
    def self.routes
      @routes
    end
    
    def self.clear
      @routes = {}
    end
    
    def self.compile(path)
      keys = []
      if path.respond_to? :to_str
        special_chars = %w{. + ( )}
        pattern =
          path.to_str.gsub(/((:\w+)|[\*#{special_chars.join}])/) do |match|
            case match
            when "*"
              keys << 'splat'
              "(.*?)"
            when *special_chars
              Regexp.escape(match)
            else
              keys << $2[1..-1]
              "([^/?&#]+)"
            end
          end
        [/^#{pattern}$/, keys]
      elsif path.respond_to?(:keys) && path.respond_to?(:match)
        [path, path.keys]
      elsif path.respond_to? :match
        [path, keys]
      else
        raise TypeError, path
      end
    end
    
    
  end
end