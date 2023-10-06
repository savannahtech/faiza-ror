# Problems with the code

# Old syntax (before_filter)
# Separation of concerns is voilated in the code as (current_user.count_hits >= 10000) should be moved to user.rb
# No data validations are used
# Tests are not written

# With above bad practices fixed, the final code will look like
# Note: Specs are provided in the separate file


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

  def over_quota?
    self.hits_count >= 10000
  end
end
  
# Our controller will look like

class ApplicationController < ActionController::API
  before_action :user_quota # New syntax

  def user_quota
    if current_user.over_quota? # Separation of concerns
      render json: { error: 'over quota' }
    else
      current_user.increment_hits_count
    end
  end
end
  
# Scheduling

gem 'whenever'
bundle exec wheneverize .

# For US
every :month, at: 'beginning of the month at 00:00', tz: 'Eastern Time (US & Canada)' do
  rake 'reset_user_quotas:reset[Eastern Time (US & Canada)]'
end

# For Australia
every :month, at: 'beginning of the month at 00:00', tz: 'Sydney' do
  rake 'reset_user_quotas:reset[Sydney]'
end

# rake file
namespace :reset_user_quotas do
  desc 'Reset user quotas at the start of every month'
  task :reset, [:timezone] => :environment do
    timezone = args[:timezone]
    users = User.where(timezone: timezone)
    users.find_each do |user|
      user.reset_hits_count
    end
  end
end


