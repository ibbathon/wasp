require 'test_helper'

class PriceScraperJobTest < ActiveJob::TestCase
  setup do
    # Set @log for minitest-logger.
    @log = Rails.logger

    # Helper vars to clean up code
    @endpoint = 'sonic_fracture'
    @url = 'https://api.warframe.market/v1/items/'+@endpoint+'/statistics'
    @response = file_fixture(@endpoint+'_price_response.json').read
    @endpoint2 = 'freeze_force'
    @url2 = 'https://api.warframe.market/v1/items/'+@endpoint2+'/statistics'
    @response2 = file_fixture(@endpoint2+'_price_response.json').read
    @all_endpoints = [
      'sonic_fracture',
      'freeze_force',
      'ember_prime_chassis',
    ]

    # Because the fixtures are designed to have two items with
    # next_price_scrape set to 0, we need to set one to now-ish so that the
    # test calls pull the correct fixture.
    Item.find_by(endpoint: 'ember_prime_chassis').
      update_attribute(:next_price_scrape, DateTime.now)
  end

  test 'single run calls API for sonic_fracture statistics' do
    data_get = stub_request(:get, @url).
      to_return(status: 200, body: @response)
    PriceScraperJob.perform_now
    assert_requested data_get
  end

  test 'two runs call API for sonic_fracture and freeze_force statistics' do
    data_get1 = stub_request(:get, @url).
      to_return(status: 200, body: @response)
    data_get2 = stub_request(:get, @url2).
      to_return(status: 200, body: @response2)
    PriceScraperJob.perform_now
    PriceScraperJob.perform_now
    assert_requested data_get1
    assert_requested data_get2
  end

  test 'updates sonic_fracture platinum' do
    # Set up the mock, execute, and grab the new item
    stub_request(:get, @url).
      to_return(status: 200, body: @response)
    PriceScraperJob.perform_now
    item = Item.find_by(endpoint: @endpoint)
    # Sonic Fracture should have a platinum value of 10.
    # Note that this is heavily dependent on which values I want to choose
    # from the miriad of statistics warframe.market API provides.
    # In the following test case, here is the algorithm:
    # 1) Go to payload/statistics_live/90days
    # 2) Find with order_type=buy, mod_rank=0
    # 3) Find latest
    # 4) Grab min_price from that
    assert_equal 10, item.platinum
  end

  test 'updates sonic_fracture next_price_scrape to 1 day later' do
    # First grab some initial dates for testing the reschedule
    now = DateTime.now
    later = 1.day.from_now - 1.second
    item = Item.find_by(endpoint: @endpoint)
    assert_operator item.next_price_scrape, :<, now
    # Set up the mock, execute, and grab the new item
    stub_request(:get, @url).
      to_return(status: 200, body: @response)
    PriceScraperJob.perform_now
    item = Item.find_by(endpoint: @endpoint)
    # Verify the rescheduled date is at least 1 day from now
    assert_operator item.next_price_scrape, :>=, later
  end

  test 'logs error if response is not 200' do
    stub_request(:get, @url).
      to_return(status: 404)
    assert_log /PriceScraperJob failed/ do
      PriceScraperJob.perform_now
    end

    stub_request(:get, @url2).
      to_return(status: 500)
    assert_log /PriceScraperJob failed/ do
      PriceScraperJob.perform_now
    end
  end

  test 'requeues regardless of success' do
    assert_enqueued_jobs 0
    stub_request(:get, @url).
      to_return(body: @response, status: 200)
    assert_enqueued_jobs 1 do
      PriceScraperJob.perform_now
    end

    stub_request(:get, @url2).
      to_return(body: @response2, status: 404)
    assert_enqueued_jobs 1 do
      PriceScraperJob.perform_now
    end
  end

  test 'does not update platinum if not 200' do
    data_get = stub_request(:get, @url).
      to_return(body: @response, status: 404)
    PriceScraperJob.perform_now
    assert_requested data_get
    item = Item.find_by(endpoint: @endpoint)
    assert_equal 0, item.platinum
  end

  test 'exits immediately if list scraper is running' do
    # Unfortunately, there's no good way to kick off the list job *and* the
    # price call *and* test their results. So, instead, we're going to manually
    # set the global var the list job uses to indicate it is running.
    $list_job_running = true
    data_get = stub_request(:get, @url).
      to_return(status: 200, body: @response)
    PriceScraperJob.perform_now
    $list_job_running = false
    assert_not_requested data_get
  end

  test 'requeues even if no items exist' do
    # This is very far on the edgecase, but we want to catch it anyways.
    Item.destroy_all
    assert_enqueued_jobs 0
    stub_request(:get, @url).
      to_return(body: @response, status: 200)
    assert_enqueued_jobs 1 do
      PriceScraperJob.perform_now
    end
  end

  test 'does not run if all next_price_scrapes are in the future' do
    Item.update_all(next_price_scrape: 5.minutes.from_now)
    data_get = stub_request(:get, '/warframe.market/').
      to_return(status: 404)
    PriceScraperJob.perform_now
    # Make sure none of the URLs were called
    assert_not_requested data_get
  end
end
