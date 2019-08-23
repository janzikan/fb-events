# frozen_string_literal: true

require 'dotenv'
Dotenv.load

module Config
  module Facebook
    class << self
      def username
        @username ||= ENV['FB_USERNAME']
      end

      def password
        @password ||= ENV['FB_PASSWORD']
      end
    end
  end
end

