require 'httparty'

class ListScraperJob < ApplicationJob
  queue_as :default

  def perform(*args)
    $list_job_running = true
    begin
      response = HTTParty.get(Rails.configuration.market_base_url+'/items')
      if !response.ok?
        Rails.logger.error "Failed to gather item list: #{response}"
      else
        data = JSON.parse response.body, symbolize_names: true
        data[:payload][:items].each do |listitem|
          dbitem = Item.find_or_create_by(endpoint: listitem[:url_name])
          dbitem.english = listitem[:item_name]
          begin
            dbitem.save!
          rescue
            Rails.logger.error "Failed to create item #{listitem[:endpoint]}"
          end
        end
      end
    rescue => e
      # If we somehow fail during this job, try again in just a bit
      Rails.logger.error "Failed to gather item list: #{e}"
      $list_job_running = false
      ListScraperJob.set(
        wait: 2.seconds
      ).perform_later
      return
    end
    $list_job_running = false

    ListScraperJob.set(
      wait_until: Rails.configuration.list_scraper_run_at.call
    ).perform_later
  end
end
