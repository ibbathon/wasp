class DataScraperJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Only run if the list job is not
    if $list_job_running
      reenqueue
      return
    end

    # Find the item with the lowest next_data_scrape
    item = Item.order(:next_data_scrape).first
    # If no items exist, just exit
    if !item
      reenqueue
      return
    end

    # Make the call to the correct endpoint
    response = HTTParty.get(Rails.configuration.market_base_url+
                            '/items/'+item.endpoint)
    if !response.ok?
      Rails.logger.error "Failed to gather item data: #{response}"
      reenqueue
      return
    end

    # We finally have the data; parse and use it
    begin
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
    rescue
      Rails.logger.error "Failed to gather item data: #{response}"
      reenqueue
      return
    end

    # Make sure to reenqueue if things went well
    reenqueue
  end

  def reenqueue
    DataScraperJob.set(
      wait: Rails.configuration.data_scraper_wait_period
    ).perform_later
  end
end
