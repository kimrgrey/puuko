module Puuko
  Response = Struct.new(:status, :headers, :body)

  class Endpoint
    class InvalidCallbackKind < StandardError; end

    CALLBACK_KINDS = [ :before, :after, :rescue ]

    DEFAULT_HEADERS = {
      "Content-Type" => "application/json"
    }

    class << self
      def registered_callbacks
        @registered_callbacks ||= begin
          hash = {}
          CALLBACK_KINDS.each do |kind|
            hash[kind] = []
            if self.superclass.respond_to?(:registered_callbacks)
              superclass.registered_callbacks[kind].each { |cb| hash[kind] << cb }
            end
          end
          hash
        end

        Hash[@registered_callbacks]
      end

      def register_callback(kind, &block)
        unless Puuko::Endpoint::CALLBACK_KINDS.include?(kind)
          raise InvalidCallbackKind, "Received invalid callback kind: #{kind}"
        end

        registered_callbacks[kind] << block if block_given?
      end

      def register_rescue_callback(exception_class, &block)
        register_callback(:rescue) do |e|
          self.instance_exec(&block) if e.is_a?(exception_class)
        end
      end

      def register_before_callback(&block)
        register_callback(:before, &block)
      end

      def register_after_callback(&block)
        register_callback(:after, &block)
      end
    end

    attr_reader :request
    attr_reader :params
    attr_reader :response

    def initialize(request, params)
      @request = request
      @params = params
      @response = Puuko::Response.new(500, DEFAULT_HEADERS, {})
      @halted = false
    end

    def execute
      result = nil

      begin
        execute_callbacks(:before)
        result = handle unless halted?
        execute_callbacks(:after)
      rescue RuntimeError, StandardError => e
        execute_callbacks(:rescue, e)
        raise e unless halted?
      end

      result
    end

    def body
      @json ||= read_request_body do |data|
        JSON.parse(data, symbolize_names: false)
      rescue JSON::ParserError
        {}
      end
    end

    protected def halt!(status: 200, headers: DEFAULT_HEADERS, body: {})
      @response = Puuko::Response.new(status, DEFAULT_HEADERS.merge(headers), body)
      @halted = true
    end

    protected def halted?
      @halted
    end

    protected def redirect_to(location)
      render status: 302, headers: { "Location" => location }
    end

    protected def render(status: 200, headers: DEFAULT_HEADERS, body: {})
      @response = Puuko::Response.new(status, DEFAULT_HEADERS.merge(headers), body)
    end

    private def execute_callbacks(kind, *args)
      return if halted?

      unless Puuko::Endpoint::CALLBACK_KINDS.include?(kind)
        raise InvalidCallbackKind, "Received invalid callback kind: #{kind}"
      end

      self.class.registered_callbacks[kind].each do |callback|
        self.instance_exec(*args, &callback)
        break if halted?
      end
    end

    private def read_request_body
      request.body.rewind # in case someone already read it
      result = yield(request.body.read)
      request.body.rewind # to allow others read it if they want
      result
    end
  end
end
