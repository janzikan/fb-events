require 'time'
require_relative '../config/facebook'
require_relative '../config/capybara'

class Scraper
  include Capybara::DSL

  class LoginFailed < StandardError; end
  class CannotRetrieveData < StandardError; end

  FB_SITE = 'https://www.facebook.com'

  def initialize
    @session = Capybara::Session.new(:webkit)
    @session.driver.header('User-Agent', 'Mozilla')
  end

  def login
    @session.visit(FB_SITE)
    @session.fill_in 'email', with: Config::Facebook.username
    @session.fill_in 'pass', with: Config::Facebook.password
    @session.find('input[type=submit]').click
  rescue Capybara::ElementNotFound
    raise LoginFailed
  end

  def profile_url
    @profile_url ||= begin
      @session.visit("#{FB_SITE}/profile.php")
      @session.current_url
    end
  end

  def friends
    @session.visit(friends_page_url)
    selector = 'div.fsl.fwb.fcb a'
    load_all_elems(selector)

    @session.all(selector).map do |link|
      next unless link['data-hovercard']
      link['data-hovercard'].match(/id=([0-9]+)/)[1]
    end.compact
  rescue Capybara::Webkit::InvalidResponseError
    raise CannotRetrieveData, 'Cannot retrieve friend IDs'
  end

  def events(user_id)
    sleep 1
    @session.visit("#{FB_SITE}/#{user_id}/upcoming_events")
    return unless @session.has_css?('a[name=Upcoming]')

    user_name = @session.title.match(/[\p{L} ]*/).to_s
    return if user_name.empty?

    selector = 'div._4cbv'
    load_all_elems(selector)
    {
      user_name: user_name,
      events: @session.all(selector).map { |node| event_info(node) }
    }
  rescue Capybara::Webkit::InvalidResponseError
    raise CannotRetrieveData, 'Cannot retrieve events'
  end

  def close_session
    driver = @session.driver
    browser = driver.instance_variable_get('@browser')
    conn = browser.instance_variable_get('@connection')
    Process.kill('TERM', conn.pid)
  end

  private

  def friends_page_url
    if profile_url.include?('profile.php')
      "#{profile_url}?sk=friends"
    else
      "#{profile_url.split('#').first}/friends"
    end
  end

  def event_info(node)
    link = node.find('a._4cbt')
    {
      id: link['href'].match(/events\/([0-9]*)/)[1],
      name: link.text,
      datetime: parse_datetime(node.find('div._4cbu').text)
    }
  end

  def load_all_elems(selector)
    loop do
      current_elems_count = elems_count(selector)
      scroll_page
      wait_for_ajax(current_elems_count, selector)

      # No new content
      break if current_elems_count == elems_count(selector)
    end
  end

  def wait_for_ajax(current_elems_count, selector)
    wait_time = 0
    interval = 0.1

    loop do
      start_time = Time.now
      sleep interval
      break if current_elems_count != elems_count(selector)
      elapsed_time = Time.now - start_time

      wait_time += elapsed_time
      break if wait_time >= 5
    end
  end

  def elems_count(selector)
    @session.all(selector).count
  end

  def scroll_page
    @session.execute_script 'window.scrollBy(0,10000)'
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
