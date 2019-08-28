# frozen_string_literal: true

module Config
  module Sidekiq
    class << self
      def redis_url
        @url ||= 'redis://localhost:6379/1'
      end
    end

    ::Sidekiq.configure_client do |config|
      config.redis = { url: redis_url }
    end

    ::Sidekiq.configure_server do |config|
      config.redis = { url: redis_url }
      config.error_handlers.clear
      config.error_handlers << Proc.new { |e, _| ::Sidekiq.logger.error e.message }
    end
  end
end
