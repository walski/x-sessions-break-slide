require 'csv'
require 'open-uri'

class Schedule
  URL = ENV['SCHEDULE_URL']
  UTC_OFFSET = -1.hour

  def initialize
    @now  = Time.now
    @date = @now.strftime('%d.%m.%y')
    @time = @now.strftime('%H:%M')

    fetch
    parse
  end

  def fetch
    @data = open(URL).read.to_s.force_encoding('utf-8')
  end

  def parse
    @doc = CSV.parse(@data)
  end

  def sessions
    day_of_event = Time.new(2013,11,22).at_midnight

    last_topic, last_speaker = []

    sessions = @doc.map do |line|
      time, topic, speaker = line
      hours, minutes = time.split(':').map(&:to_i)
      time = day_of_event + hours.hours + minutes.minutes + UTC_OFFSET

      if topic && !topic.blank? && speaker && !speaker.blank?
        {'info' => topic, 'speaker' => speaker, 'time' => time, 'timestamp' => time.to_i}
      else
        nil
      end
    end.compact

    sessions.each_with_index do |session, i|
      next_session = sessions[i+1] || {}

      session['end'] = next_session['time'] || session['time']
    end

    sessions
  end

  def now
    current_time = Time.now
    last_session = nil
    sessions.each do |session|
      return last_session if session['time'] > current_time
      last_session = session
    end
    last_session
  end

  def next
    current_time = Time.now

    sessions.each do |session|
      return session if session['time'] > current_time
    end
    nil
  end

  def self.all
    instance = new
    instance.fetch
    instance.parse
    instance.sessions
  end
end
