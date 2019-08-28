# frozen_string_literal: true

require 'multi_json'
require 'sidekiq'
require 'timeout'

require_relative '../config/sidekiq'
require_relative '../config/redis'
require_relative '../models/scraper'

class ScrapeEvents
  include Sidekiq::Worker

  TIMEOUT = 60 # 1 minute

  sidekiq_options retry: 2, queue: :fb_events_scraping, backtrace: false

  def perform(user_id)
    logger.info "Processing: #{user_id}"

    data = fetch_data(user_id)

    unless data
      logger.info 'No events found'
      return
    end

    @redis = Config::Redis.connection
    @key = Config::Redis::KEY_EVENTS

    save_data(data)
  end

  private

  def fetch_data(user_id)
    scraper = Scraper.new

    Timeout.timeout(TIMEOUT) do
      scraper.login
      scraper.events(user_id)
    end
  ensure
    scraper.close_session
  end

  def save_data(data)
    user_name = data[:user_name]
    data[:events].each { |event| save_event(user_name, event) }
  end

  def save_event(user_name, event)
    event_id = event.delete(:id)

    # Add participant
    @redis.sadd("#{@key}_#{event_id}", user_name)

    # Event already exists
    return if @redis.hexists(@key, event_id)

    @redis.hset(@key, event_id, MultiJson.dump(event))
  end
end
