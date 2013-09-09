# Load the rails application.
require File.expand_path('../application', __FILE__)

# Initialize the rails application.
Potlucky::Application.initialize!


ActionMailer::Base.smtp_settings = {
  :user_name => ENV['EMAILUSERNAME'],
  :password => ENV['EMAILPASSWORD'],
#  :domain => '',
  :address => 'smtp.gmail.com',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}
