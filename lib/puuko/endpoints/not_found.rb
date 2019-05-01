module Puuko
  module Endpoints
    class NotFound < Puuko::Endpoint
      def handle
        render status: 404
      end
    end
  end
end
