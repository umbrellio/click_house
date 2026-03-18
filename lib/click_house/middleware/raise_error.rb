# frozen_string_literal: true

module ClickHouse
  module Middleware
    class RaiseError < Faraday::Middleware
      EXCEPTION_CODE_HEADER = 'x-clickhouse-exception-code'
      MAX_RETRIES = 5
      SLEEP_INTERVAL = 0.5

      Faraday::Response.register_middleware self => self

      # @param env [Faraday::Env]
      def call(env)
        retries = 0

        begin
          super
        rescue Faraday::ConnectionFailed => e
          if e.message.include?('end of file reached')
            retries += 1
            raise if retries > MAX_RETRIES

            Kernel.sleep(SLEEP_INTERVAL)
            retry
          else
            raise NetworkException, e.message, e.backtrace
          end
        end
      end

      # @param env [Faraday::Env]
      def on_complete(env)
        if env.response_headers.include?(EXCEPTION_CODE_HEADER) ||
           !env.success? || env.body.include?('DB::Exception')
          raise DbException, "[#{env.status}] #{env.body}"
        end
      end
    end
  end
end
