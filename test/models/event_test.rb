require 'test_helper'

class EventTest < ActiveSupport::TestCase

  test "availabilities - returns an array with the available date and times in a week time" do

    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal '2014/08/10', availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal '2014/08/11', availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal '2014/08/16', availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  test "availabilities - does not show duplicate openings" do

    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-11 08:30"), ends_at: DateTime.parse("2014-08-11 13:00")

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal '2014/08/10', availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal '2014/08/11', availabilities[1][:date]
    assert_equal ["8:30", "9:00", "9:30", "10:00", "11:30", "12:00", "12:30"], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal '2014/08/16', availabilities[6][:date]
    assert_equal 7, availabilities.length
  end

  test "get_appointment_slots - returns an array of date time slots between two given datetime points" do

    slots = Event.get_appointment_slots(DateTime.new(2019, 8, 10, 9, 0), DateTime.new(2019, 8, 10, 12, 30))

    assert_equal 7, slots.length
    assert_equal DateTime.new(2019, 8, 10, 9, 30), slots[1]
  end

end
