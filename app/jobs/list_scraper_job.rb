require 'httparty'

class ListScraperJob < ApplicationJob
  queue_as :default

  def perform(*args)
    response = HTTParty.get(Rails.configuration.market_base_url+'/items')
    if !response.ok?
      Rails.logger.error "Failed to gather item list: #{response}"
    else
      data = JSON.parse response.body, symbolize_names: true
      data[:payload][:items][:en].each do |listitem|
        dbitem = Item.find_or_create_by(endpoint: listitem[:url_name])
        dbitem.english = listitem[:item_name]
        begin
          dbitem.save!
        rescue
          Rails.logger.error "Failed to create item #{listitem[:endpoint]}"
        end
      end
    end

    ListScraperJob.set(
      wait_until: Rails.configuration.list_scraper_run_at.call
    ).perform_later
  end
end
