# Solution
# Instead of using query to count the hits on every call, 
# we should use Rails cache, it will be fast as well as it will have linear time fetching the counts.
# We will store the "user_#{id}_hits_count" as keys and values will be integers


# Code

class User < ApplicationRecord
  def hits_count
    Rails.cache.read("user_#{id}_hits_count").to_i
  end

  def increment_hits_count
    Rails.cache.increment("user_#{id}_hits_count")
  end

  def reset_hits_count
    Rails.cache.write("user_#{id}_hits_count", 0)
  end

end

# So our controller will look like

class ApplicationController < ActionController::API
  before_filter :user_quota

  def user_quota
    if current_user.hits_count >= 10000
      render json: { error: 'over quota' }
    else
      current_user.increment_hits_count
    end
  end
end

# For resetting quota, we will write a job that will run on start of every month and reset the quotas for all the users
# This will be very feasible because all the heavy work of resetting quota will be done once a month in background job
# For scheduling, we can use whenever gem or Active Job or sidekiq

gem 'whenever'
bundle exec wheneverize .

# config/schedule.rb
every :month, at: 'beginning of the month at 00:00' do
  rake 'reset_user_quotas:reset'
end

# lib/tasks/reset_user_quotas.rake
namespace :reset_user_quotas do
  desc 'Reset user quotas at the start of every month'
  task :reset => :environment do
    User.find_each do |user|
      user.reset_hits_count
    end
  end
end