# frozen_string_literal: true

require 'redis'
require 'hiredis'

module Config
  module Redis
    KEY_EVENTS = 'events'

    class << self
      def url
        @url ||= 'redis://localhost:6379/0'
      end

      def connection
        @conn ||= ::Redis.new(url: url, driver: :hiredis)
      end
    end
  end
end
