class DataScraperJob < ApplicationJob
  queue_as :default

  after_perform do |job|
    reenqueue
  end

  rescue_from Exception do |e|
    Rails.logger.error "DataScraperJob failed: #{e}"
    reenqueue
    # Assume the error will repeat, so set the next_data_scrape so we don't
    # reattempt this one immediately.
    begin
      item = Item.order(:next_data_scrape).first
      item.next_data_scrape = 7.days.from_now
      item.save!
    rescue
    end
  end

  def perform(*args)
    # Only run if the list job is not
    return if $list_job_running

    # Find the item with the lowest next_data_scrape
    item = Item.order(:next_data_scrape).first
    # If the item has a next_data_scrape in the future, just exit
    return if item.next_data_scrape > 1.second.ago
    # Make the call to the correct endpoint
    response = HTTParty.get(Rails.configuration.market_base_url+
                            '/items/'+item.endpoint)
    if !response.ok?
      Rails.logger.error "DataScraperJob failed: #{response}"
      return
    end

    # We finally have the data; parse and use it
    data = JSON.parse response.body, symbolize_names: true
    sources = data[:payload][:item][:items_in_set].select do |i|
      i[:en][:item_name] == item.english
    end[0][:en][:drop]
    sources = sources.collect do |s|
      Source.find_or_create_by english: s[:name]
    end

    item.sources = sources

    # Schedule the next data scrape for this item
    item.next_data_scrape = 7.days.from_now
    item.save!
  end

  def reenqueue
    DataScraperJob.set(
      wait: Rails.configuration.data_scraper_wait_period
    ).perform_later
  end
end
