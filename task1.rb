# Solution
# Instead of using query to count the hits on every call, 
# we should use Rails cache, it will be fast as well as it will have linear time fetching the counts.
# We will store the "user_#{id}_hits_count" as keys and values will be integers
# We will also store the "user_#{id}_last_reset_datetime" which will store the date and time of last quota reset, it will help us checking the quota

# Another problem with the current code is that it is considering start of month and end of month as same for every user
# For example, start of month will be 1st of every month and end of month will be last of every month for every user
# but for each user, the start of month will be different,
# start if month for each user should be the date when he/she first bought the subscription
# this problem is also solved with my solution, because we are now storing reset info of individual users

# Code

class User < ApplicationRecord

  def reset_quota_if_needed
    current_datetime = DateTime.now
    last_reset_datetime = DateTime.parse self.last_reset_datetime
    hours_difference = ((current_datetime - last_reset_datetime) * 24).to_i
    if hours_difference >= 720 # 30 days, hours are used instead of days to be more precise about the reseting
      extra_hours = hours_difference - 720 
      # lets say a user's quota was supposed to reset at 11 October. but he has not used API till 15 October, 
      # so in order to determine the date for reseting quota, we need to subtract extra hours from the current date 
      # otherwise his quota will be reset on 15 Octobar which is not supposed to be
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

# So our controller will look like

class ApplicationController < ActionController::API
  before_filter :user_quota

  def user_quota
    
    current_user.reset_quota_if_needed

    if current_user.hits_count >= 10000
      render json: { error: 'over quota' }
    else
      current_user.increment_hits_count
    end
  end
end