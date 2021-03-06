require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Wasp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # warframe.market API base URL
    config.market_base_url = 'https://api.warframe.market/v1'
    # When to run the ListScraperJob (recurring)
    config.list_scraper_run_at = lambda { DateTime.tomorrow.beginning_of_day }
    # How long to wait between DataScraperJob runs
    config.data_scraper_wait_period = 2.seconds
    # How long to wait between PriceScraperJob runs
    config.price_scraper_wait_period = 2.seconds
  end
end
