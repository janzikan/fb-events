# frozen_string_literal: true

require 'multi_json'
require 'time'

require_relative '../config/redis'

class Events
  def initialize
    @redis = Config::Redis.connection
    @key = Config::Redis::KEY_EVENTS
  end

  def all
    @events ||= load_events.sort_by { |k, v| v[:datetime] }.to_h
  end

  private

  def load_events
    @redis.hgetall(@key).inject({}) do |hsh, (event_id, event)|
      event = MultiJson.load(event, symbolize_keys: true)
      event[:participants] = participants(event_id)
      event[:datetime] = parse_datetime(event[:datetime])
      hsh.merge(event_id => event)
    end
  end

  def participants(event_id)
    @redis.smembers("#{@key}_#{event_id}").sort
  end

  def parse_datetime(str)
    date = parse_date(str)
    time = Time.parse(str)
    Time.mktime(date.year, date.month, date.day, time.hour, time.min)
  rescue ArgumentError
    nil
  end

  def parse_date(str)
    today = Date.today

    if str.start_with?('At')
      date = today
    elsif str.start_with?('Tomorrow')
      date = today + 1
    else
      date = Date.parse(str)
      date += 7 if date < today
    end

    date
  end
end
