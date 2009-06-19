if Rails.env.production?
  APP_CONFIG = ENV
else
  APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/importer.yml")[RAILS_ENV]
end