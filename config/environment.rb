# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Set up our logger
Rails.logger = Logger.new("log/#{Rails.env}.log")
