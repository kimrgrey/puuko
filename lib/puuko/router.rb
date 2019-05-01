module Puuko
  def self.router(&block)
    router_class = Class.new(Puuko::Router)
    router_class.routing = block
    router_class
  end

  class Router
    class << self
      def routing
        @routing
      end

      def routing=(block)
        @routing = block
      end
    end

    def apply(application)
      application.instance_eval(&self.class.routing)
    end
  end
end
