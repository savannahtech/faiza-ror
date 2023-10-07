# As the logs show, the Australian time is 10 hours ahead of the system's time, 
# so even if the next month is started in Australia, system's month will update after 10 hours, 
# during which the Australian users will not be able to make more calls if they have exceeded quota for previous month, 
# and after the system is also in next month, then the users will be able to make more hits.

# Solution

# save timezone in users table
# we can extract the timezone of a user from the request or we can ask the user to update his/her timezone, either way, we should have timezone field in the users table

# now we need to make sure that when we are processing any time related logic, we should always consider timezones
# so that every user has his last reset info based on his timezone

# so our updated user.rb will look like

class User < ApplicationRecord

  def reset_quota_if_needed
    current_datetime = DateTime.now.in_time_zone(self.timezone)
    last_reset_datetime = DateTime.parse self.last_reset_datetime
    hours_difference = ((current_datetime - last_reset_datetime) * 24).to_i
    if hours_difference >= 720 # 30 days, hours are used instead of days to be more precise about the reseting
      extra_hours = hours_difference - 720
      current.reset_hits_count(current_datetime - extra_hours.hours)
    end
  end

  def last_reset_datetime
    Rails.cache.read("user_#{id}_last_reset_datetime")
  end

  def hits_count
    Rails.cache.read("user_#{id}_hits_count").to_i
  end

  def increment_hits_count
    Rails.cache.increment("user_#{id}_hits_count")
  end

  def reset_hits_count(datetime)
    Rails.cache.write("user_#{id}_hits_count", 0)
    Rails.cache.write("user_#{id}_last_reset_datetime", datetime)
  end

end