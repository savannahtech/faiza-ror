# As the logs show, the Australian time is 10 hours ahead of the system's time, 
# so even if the next month is started in Australia, system's month will update after 10 hours, 
# during which the Australian users will not be able to make more calls if they have exceeded quota for previous month, 
# and after the system is also in next month, then the users will be able to make more hits.

# Solution

# save timezone in users table
# we can extract the timezone of a user from the request or we can ask the user to update his/her timezone, either way, we should have timezone field in the users table

# we also need to make sure that for every different time zone we are supporting, 
# we will run the job on start of every month(of a particular timezone) that will reset quota for its users


# so now our config/schedule.rb file will look like

# For US
every :month, at: 'beginning of the month at 00:00', tz: 'Eastern Time (US & Canada)' do
  rake 'reset_user_quotas:reset[Eastern Time (US & Canada)]'
end

# For Australia
every :month, at: 'beginning of the month at 00:00', tz: 'Sydney' do
  rake 'reset_user_quotas:reset[Sydney]'
end

# Now, our rake file will look like
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