class PriceScraperJob < ApplicationJob
  queue_as :default

  after_perform { |job| reenqueue }

  rescue_from Exception do |e|
    Rails.logger.error "PriceScraperJob failed: #{e}"
    reenqueue
    # Assume the error will repeat, so set the next_price_scrape so we don't
    # reattempt this one immediately.
    begin
      @item.next_price_scrape = 1.day.from_now
      @item.save!
    rescue
    end
  end

  def perform(*args)
    # Only run if the list job is not
    return if $list_job_running

    # Find the item with the lowest next_price_scrape
    @item = Item.order(:next_price_scrape).first
    # If the item has a next_price_scrape in the future, just exit
    return if @item.next_price_scrape > 1.second.ago
    # Make the call to the correct endpoint
    response = HTTParty.get(Rails.configuration.market_base_url+
                            '/items/'+@item.endpoint+'/statistics')
    if !response.ok?
      Rails.logger.error "PriceScraperJob failed: #{response}"
      return
    end

    # We finally have the data; parse and use it
    data = JSON.parse response.body, symbolize_names: true
    @item.platinum = choose_platinum_value data

    # Schedule the next data scrape for this item
    @item.next_price_scrape = 1.day.from_now
    @item.save!
  end

  def reenqueue
    PriceScraperJob.set(
      wait: Rails.configuration.price_scraper_wait_period
    ).perform_later
  end

  def choose_platinum_value data
    begin
      orders = data[:payload]
      # Find any orders, preferring live over closed, 90days over 48hours
      preferred_order = [
        orders[:statistics_live]['90days'.to_sym],
        orders[:statistics_live]['48hours'.to_sym],
        orders[:statistics_closed]['90days'.to_sym],
        orders[:statistics_closed]['48hours'.to_sym],
      ]
      preferred_order.each do |po|
        po.select! { |o| o[:order_type].nil? || o[:order_type] == 'buy' }
        next if po.length == 0
        orders = po
        break
      end
      # Find with order_type=buy, mod_rank=0
      orders.select! { |o| o[:mod_rank].nil? || o[:mod_rank] == 0 }
      # Find latest
      latest = orders.max_by { |o| o[:datetime] }
      # Grab min_price
      return latest[:min_price]
    rescue => e
      Rails.logger.error "No price found for #{@item.english}: #{e}"
      Rails.logger.debug "No price found for #{@item.english}; data==#{data}"
      return 0
    end
  end
end
