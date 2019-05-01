module Puuko
  class Configuration
    attr_accessor :logger
    attr_accessor :session_secret

    attr_reader :before_filters
    attr_reader :after_filters

    def initialize
      @before_filters = []
      @after_filters = []
    end

    def before(&block)
      @before_filters << block
    end

    def after(&block)
      @after_filters << block
    end
  end
end
