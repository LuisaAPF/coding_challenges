class Event < ApplicationRecord

  APPOINTMENT_DURATION = 0.5 / 24 # days (or half an hour)

  # Returns the available dates and respective time slots in a week period,
  # starting from `initial_datetime`
  # Example return:
  # [{:date=>"2014/08/10", :slots=>[]},
  # {:date=>"2014/08/11", :slots=>["9:30", "10:00", "11:30", "12:00"]},
  # {:date=>"2014/08/12", :slots=>[]},
  # {:date=>"2014/08/13", :slots=>[]},
  # {:date=>"2014/08/14", :slots=>[]},
  # {:date=>"2014/08/15", :slots=>[]},
  # {:date=>"2014/08/16", :slots=>[]}]
  def self.availabilities(initial_datetime)
    final_datetime = initial_datetime + 7

    # Array with the datetimes of all openings between
    # `initial_datetime` and `final_datetime` (excluded)
    week_openings = Event.where("starts_at >= ? AND ends_at < ? AND kind = 'opening'", initial_datetime, final_datetime).map do |r|
      Event.get_appointment_slots(r.starts_at.to_datetime, r.ends_at.to_datetime)
    end
    week_openings = week_openings.flatten

    # Array with the datetimes of all appointments between `initial_datetime`
    # and `final_datetime` (excluded)
    week_appointments = Event.where("starts_at >= ? AND ends_at < ? AND kind = 'appointment'", initial_datetime, final_datetime).map do |r|
      Event.get_appointment_slots(r.starts_at.to_datetime, r.ends_at.to_datetime)
    end
    week_appointments = week_appointments.flatten

    # Hash mapping the weekday number to the corresponding datetime
    # for all the seven days between `initial_datetime` and `final_datetime` (excluded)
    weekday_datetime_map = {}
    (initial_datetime..final_datetime - 1).each do |dt|
      weekday_datetime_map[dt.wday] = dt
    end

    # Array with the datetimes of all recurring openings between `initial_datetime`
    # and `final_datetime` (excluded)
    recurring_openings = Event.where("weekly_recurring = true AND kind = 'opening'").map do |r|
      datetime_match = weekday_datetime_map[r.starts_at.wday]

      Event.get_appointment_slots(r.starts_at.to_datetime, r.ends_at.to_datetime).map do |dt|
        DateTime.new(datetime_match.year, datetime_match.month, datetime_match.day, dt.hour, dt.min)
      end
    end
    recurring_openings = recurring_openings.flatten

    # Array with all available datetimes
    available_dates = week_openings.concat(recurring_openings).uniq.difference(week_appointments)

    # Formatting the end result according to the example on the function doc.
    availabilities = []
    weekday_datetime_map.each do |k, v|
      time_slots = available_dates.filter {|d| d.strftime("%Y/%m/%d") == v.strftime("%Y/%m/%d")}
      .map {|d| d.strftime("%k:%M").strip}

      availabilities.push({date: v.strftime("%Y/%m/%d"), slots: time_slots})
    end

    availabilities
  end

  # Returns all the datetime slots between `initial_datetime` and
  # `final_datetime`, with a step defined by `APPOINTMENT_DURATION`
  def self.get_appointment_slots(initial_datetime, final_datetime)
    appointment_slots = []
    dt = initial_datetime

    while dt < final_datetime do
      appointment_slots.push(dt)
      dt = dt + APPOINTMENT_DURATION
    end

    appointment_slots
  end

end
