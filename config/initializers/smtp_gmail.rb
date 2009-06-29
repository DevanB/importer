# This file is automatically copied into RAILS_ROOT/initializers

require "smtp_tls"

ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true,
  :user_name => 'jadedpixel@gmail.com',
  :password => 'Ultimate'
}
