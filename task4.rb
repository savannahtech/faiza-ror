# Problems with the code

# Old syntax (before_filter)

# Separation of concerns is voilated in the code as (current_user.count_hits >= 10000) should be moved to user.rb

# No security measures are applied
# we should protection against csrf, for that we should include csrf token to every request that submits some data
# we should also use api token for each user
# we should use safe_params for any data that is submitted so that users are not able to submit additional parameters
# this will also help to secure the site from sql_injection
# this will also help to protect the site form "Mass Assignment"

# No data validations are used
# we should also validate the data, for example, if a date is passed in the data, we should validate its format 
# if user tries to input his name, we should validate that name should not contain any special characters, etc.

# Tests are not written

# With above bad practices fixed, the final code will look like
# Note: Specs are provided in the separate file

class User < ApplicationRecord

  def reset_quota_if_needed
    current_datetime = DateTime.now
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

  def over_quota?
    self.hits_count >= 10000
  end

end
  
# Our controller will look like

class ApplicationController < ActionController::API
  before_action :user_quota # New syntax

  def user_quota
    current_user.reset_quota_if_needed

    if current_user.over_quota? # Separation of concerns
      render json: { error: 'over quota' }
    else
      current_user.increment_hits_count
    end
  end
end


