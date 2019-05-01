require "json"

require_relative "base"
require_relative "endpoints/not_found"

module Puuko
  Route = Struct.new(:verb, :path, :endpoint, :params)

  class Application
    class << self
      def configure(klass = nil)
        @configuration = klass.new if klass
        yield @configuration if block_given?
        @configuration
      end

      def logger
        @configuration.logger
      end

      def configuration
        @configuration
      end
    end

    def initialize
      @routes = []
    end

    def get(path, to: Puuko::Endpoints::NotFound, params: {})
      @routes << Puuko::Route.new(:get, path, to, params)
    end

    def post(path, to: Puuko::Endpoints::NotFound, params: {})
      @routes << Puuko::Route.new(:post, path, to, params)
    end

    def put(path, to: Puuko::Endpoints::NotFound, params: {})
      @routes << Puuko::Route.new(:put, path, to, params)
    end

    def patch(path, to: Puuko::Endpoints::NotFound, params: {})
      @routes << Puuko::Route.new(:patch, path, to, params)
    end

    def delete(path, to: Puuko::Endpoints::NotFound, params: {})
      @routes << Puuko::Route.new(:delete, path, to, params)
    end

    def configuration
      self.class.configuration
    end

    def logger
      self.class.logger
    end

    def router=(router)
      router.apply(self)
    end

    def rack_app
      klass = Class.new(Puuko::Base) do
        set :protection, except: :json_csrf

        configure :production, :development do
          enable :logging
        end
      end

      configuration.before_filters.each do |before_filter|
        klass.before(&before_filter)
      end

      @routes.each do |route|
        logger.debug "Register #{route.verb} #{route.path} to #{route.endpoint.name}"

        klass.public_send(route.verb, route.path) do
          handler = route.endpoint.new(request, route.params.merge(params))
          handler.execute

          [
            handler.response.status,
            handler.response.headers,
            handler.response.body.to_json
          ]
        end
      end

      configuration.after_filters.each do |after_filter|
        klass.after(&after_filter)
      end

      klass
    end
  end
end
