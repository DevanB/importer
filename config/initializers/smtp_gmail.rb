# This file is automatically copied into RAILS_ROOT/initializers

require "smtp_tls"

config_options = {:user_name => ENV['gmail_user'], :password => ENV['gmail_pass']}
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}.merge(config_options) # Configuration options override default options
