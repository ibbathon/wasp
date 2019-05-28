set :output, {
  standard: "#{path}/log/cron.log",
  error: "#{path}/log/cron-error.log"
}

env :PATH, ENV['PATH']
env :BUNDLE_PATH, ENV['BUNDLE_PATH']

every :hour do
  rake 'scraper:fetch_prices'
end

every :day do
  rake 'scraper:fetch_items'
end
