module Fredo
  class StubSocket #:nodoc:

    def initialize(*args)
    end

    def closed?
      @closed ||= true
    end

    def readuntil(*args)
    end

  end
end