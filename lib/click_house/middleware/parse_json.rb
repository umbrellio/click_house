# frozen_string_literal: true

module ClickHouse
  module Middleware
    class ParseJson < ResponseBase
      Faraday::Response.register_middleware self => self

      # @param env [Faraday::Env]
      def on_complete(env)
        env.body = JSON.parse(env.body, config.json_load_options) if json?(env.body)
      end

      private

      def json?(str)
        !str.strip.empty? && str.strip =~ /^(\[|\{)/
      end
    end
  end
end
