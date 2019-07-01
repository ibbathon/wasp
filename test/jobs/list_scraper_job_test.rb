require 'test_helper'

class ListScraperJobTest < ActiveJob::TestCase
  setup do
    # Set @log for minitest-logger.
    @log = Rails.logger

    # Easy reference for which items were added.
    @new_items = [
      {'endpoint': 'ember_prime_neuroptics', 'english': 'Ember Prime Neuroptics'},
      {'endpoint': 'icy_avalanche', 'english': 'Icy Avalanche'},
    ]

    @endpoint = 'https://api.warframe.market/v1/items'
    @response_body = file_fixture('list_response.json').read
  end

  test 'calls warframe.market API /items endpoint' do
    items_get = stub_request(:get, @endpoint).
      to_return(status: 200, body: @response_body)
    ListScraperJob.perform_now
    assert_requested items_get
  end

  test 'logs error if response is not 200' do
    stub_request(:get, @endpoint).
      to_return(status: 404)
    assert_log /Failed to gather item list/ do
      ListScraperJob.perform_now
    end

    stub_request(:get, @endpoint).
      to_return(status: 500)
    assert_log /Failed to gather item list/ do
      ListScraperJob.perform_now
    end
  end

  test 'requeues regardless of success' do
    stub_request(:get, @endpoint).
      to_return(body: @response_body, status: 200)
    assert_enqueued_jobs 1 do
      ListScraperJob.perform_now
    end

    stub_request(:get, @endpoint).
      to_return(body: @response_body, status: 404)
    assert_enqueued_jobs 1 do
      ListScraperJob.perform_now
    end
  end

  test 'does not create items if not 200' do
    stub_request(:get, @endpoint).
      to_return(body: @response_body, status: 404)
    ListScraperJob.perform_now
    @new_items.each do |item|
      assert_equal 0, Item.where(
        endpoint: item[:endpoint], english: item[:english]
      ).count, "item #{item[:endpoint]} incorrectly created"
    end
  end

  test 'creates items for each item in response' do
    stub_request(:get, @endpoint).
      to_return(body: @response_body, status: 200)
    ListScraperJob.perform_now
    @new_items.each do |item|
      assert_equal 1, Item.where(
        endpoint: item[:endpoint], english: item[:english]
      ).count, "item #{item[:endpoint]} not created"
    end
  end

  test 'does not overwrite other attributes for items' do
    # Pre-create one of the items with an extra attribute.
    Item.create(
      endpoint: 'ember_prime_neuroptics',
      english: 'blah',
      platinum: 20
    )

    stub_request(:get, @endpoint).
      to_return(body: @response_body, status: 200)
    ListScraperJob.perform_now

    # Make sure the extra attribute remains, but english has been overwritten.
    item = Item.find_by(endpoint: 'ember_prime_neuroptics')
    refute_nil item
    assert_equal 'Ember Prime Neuroptics', item.english
    assert_equal 20, item.platinum
  end
end
