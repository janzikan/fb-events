# frozen_string_literal: true

class Event
  attr_reader :id, :name, :datetime

  def initialize(id, name, datetime, participant)
    @id = id
    @name = name
    @datetime = datetime
    @participants = Set.new
    add_participant(participant)
  end

  def add_participant(participant)
    @participants.add(participant)
  end

  def participants
    @participants.sort
  end

  def <=>(event)
    return 0 if datetime.nil? && event.datetime.nil?
    return 1 if datetime.nil?
    return -1 if event.datetime.nil?
    datetime <=> event.datetime
  end
end
