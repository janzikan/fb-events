require_relative 'event'

class EventsList
  @events = {}

  class << self
    def events
      @events.values.sort
    end

    def add_events(participant, events)
      events.each do |event|
        add_event(event[:id], event[:name], event[:datetime], participant)
      end
    end

    private

    def add_event(id, name, datetime, participant)
      if @events.has_key?(id)
        @events[id].add_participant(participant)
      else
        @events[id] = Event.new(id, name, datetime, participant)
      end
    end
  end
end
