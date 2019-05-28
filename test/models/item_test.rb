require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  setup do
    @source = Source.create(endpoint: 'test_source', english: 'Test Source')
    @data = {
      endpoint: 'test_item',
      english: 'Test Item',
      source: @source,
      cost: 1234,
      scrape: true,
      platinum: 5678,
      last_scraped: DateTime.new(2019,01,01,0,0,0),
    }
  end

  def remove_field_and_return_item field
    @data.delete(field)
    return Item.create!(@data)
  end

  def remove_field_and_test_invalid field
    assert_raises ActiveRecord::RecordInvalid do
      remove_field_and_return_item field
    end
  end

  def remove_field_and_test_default field, default_value
    item = remove_field_and_return_item field
    assert_equal default_value, item[field]
  end

  test 'endpoint is required' do
    remove_field_and_test_invalid :endpoint
  end

  test 'english is required' do
    remove_field_and_test_invalid :english
  end

  test 'source is required' do
    remove_field_and_test_invalid :source
  end

  test 'cost defaults to 0' do
    remove_field_and_test_default :cost, 0
  end

  test 'scrape defaults to false' do
    remove_field_and_test_default :scrape, false
  end

  test 'platinum defaults to 0' do
    remove_field_and_test_default :platinum, 0
  end

  test 'last_scraped defaults to ancient' do
    remove_field_and_test_default :last_scraped, DateTime.new(0)
  end
end
