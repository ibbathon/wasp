require 'test_helper'

class DataScraperJobTest < ActiveJob::TestCase
  setup do
    # Set @log for minitest-logger.
    @log = Rails.logger

    # The order in which items should be scraped.
    @endpoints = [
      'sonic_fracture',
      'ember_prime_chassis',
      'freeze_force'
    ]

    # The URLs to be hit
    base_url = 'https://api.warframe.market/v1/items/'
    @urls = @endpoints.collect { |e| base_url+e }

    # The sample data from data scrapes (cleaned and simplified).
    @responses = @endpoints.collect do |e|
      file_fixture(e+'_data_response.json').read
    end
  end

  test 'single call calls warframe.market API /items/ember_prime_chassis URL' do
    data_get = stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    DataScraperJob.perform_now
    assert_requested data_get
  end

  test 'two calls call warframe.market API /items/ember_prime_chassis and sonic_fracture URLs' do
    data_get1 = stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    data_get2 = stub_request(:get, @urls[1]).
      to_return(status: 200, body: @responses[1])
    DataScraperJob.perform_now
    DataScraperJob.perform_now
    assert_requested data_get1
    assert_requested data_get2
  end

  test 'updates sonic_fracture sources' do
    # Set up the mock, execute, and grab the new item
    stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    DataScraperJob.perform_now
    item = Item.find_by(endpoint: @endpoints[0])
    # Sonic Fracture should have two sources
    assert_equal 2, item.sources.count
    assert_includes item.sources, Source.find_by(english: 'The Perrin Sequence')
    assert_includes item.sources, Source.find_by(english: 'Cephalon Suda')
  end

  test 'updates sonic_fracture next_data_scrape to 7 days later' do
    # First grab some initial dates for testing the reschedule
    now = DateTime.now
    later = 7.days.from_now - 1.second
    item = Item.find_by(endpoint: @endpoints[0])
    assert_operator item.next_data_scrape, :<, now
    # Set up the mock, execute, and grab the new item
    stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    DataScraperJob.perform_now
    item = Item.find_by(endpoint: @endpoints[0])
    # Verify the rescheduled date is at least 7 days from now
    assert_operator item.next_data_scrape, :>=, later
  end

  test 'updates ember_prime_chassis sources to correct values' do
    # The responses from the API can put the item at index >0 in items_in_set.
    # So we should test to make sure it grabs the correct item.

    # Need to call job twice to get ember_prime_chassis populated
    stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    stub_request(:get, @urls[1]).
      to_return(status: 200, body: @responses[1])
    DataScraperJob.perform_now
    DataScraperJob.perform_now
    # Grab the item and verify its sources
    item = Item.find_by(endpoint: @endpoints[1])
    assert_equal 2, item.sources.count
    assert_includes item.sources, Source.find_by(english: 'Meso F2 Uncommon')
    assert_includes item.sources, Source.find_by(english: 'Neo F1 Uncommon')
  end

  test 'logs error if response is not 200' do
    stub_request(:get, @urls[0]).
      to_return(status: 404)
    assert_log /DataScraperJob failed/ do
      DataScraperJob.perform_now
    end

    stub_request(:get, @urls[0]).
      to_return(status: 500)
    assert_log /DataScraperJob failed/ do
      DataScraperJob.perform_now
    end
  end

  test 'requeues regardless of success' do
    assert_enqueued_jobs 0
    stub_request(:get, @urls[0]).
      to_return(body: @responses[0], status: 200)
    assert_enqueued_jobs 1 do
      DataScraperJob.perform_now
    end

    stub_request(:get, @urls[1]).
      to_return(body: @responses[1], status: 404)
    assert_enqueued_jobs 1 do
      DataScraperJob.perform_now
    end
  end

  test 'does not update sources if not 200' do
    data_get = stub_request(:get, @urls[0]).
      to_return(body: @responses[0], status: 404)
    DataScraperJob.perform_now
    assert_requested data_get
    item = Item.find_by(endpoint: @endpoints[0])
    assert_equal 0, item.sources.count
  end

  test 'exits immediately if list scraper is running' do
    # Unfortunately, there's no good way to kick off the list job *and* the
    # data call *and* test their results. So, instead, we're going to manually
    # set the global var the list job uses to indicate it is running.
    $list_job_running = true
    data_get = stub_request(:get, @urls[0]).
      to_return(status: 200, body: @responses[0])
    DataScraperJob.perform_now
    $list_job_running = false
    assert_not_requested data_get
  end

  test 'requeues even if no items exist' do
    # This is very far on the edgecase, but we want to catch it anyways.
    Item.destroy_all
    assert_enqueued_jobs 0
    stub_request(:get, @urls[0]).
      to_return(body: @responses[0], status: 200)
    assert_enqueued_jobs 1 do
      DataScraperJob.perform_now
    end
  end

  test 'does not run if all next_data_scrapes are in the future' do
    @endpoints.each do |e|
      Item.find_by(endpoint: e).update_attribute(:next_data_scrape, 5.minutes.from_now)
    end
    data_gets = @urls.collect.with_index do |u,i|
      stub_request(:get, u).
        to_return(body: @responses[i], status: 200)
    end
    DataScraperJob.perform_now
    # Make sure none of the URLs were called
    data_gets.each { |d| assert_not_requested d }
  end
end
