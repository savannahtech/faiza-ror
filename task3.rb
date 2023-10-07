# Again this is due to timezone differences, suppose a user is 10 hours behind the systems time, 
# so when the system will get into the next month, that user will still be in the previous month, 
# and with current implementation, the system will count that user's quota in next month and user will still 
# be able to make more hits still being in the previous month


# Solution

# When we will reset quota according to the timezones, 
# it will be also fixed, because now every user's quota will be reset according to his/her timezone