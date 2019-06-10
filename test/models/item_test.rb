require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  setup do
    @source = Source.create(endpoint: 'test_source', english: 'Test Source')
    @data = {
      endpoint: 'test_item',
      english: 'Test Item',
      source: @source,
      cost: 1234,
      platinum: 5678,
      next_price_scrape: DateTime.new(2019,01,01,0,0,0),
      next_data_scrape: DateTime.new(2019,01,01,0,0,0),
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

  def remove_field_and_test_null_default field
    item = remove_field_and_return_item field
    assert_nil item[field]
  end

  test 'endpoint is required' do
    remove_field_and_test_invalid :endpoint
  end

  test 'english is required' do
    remove_field_and_test_invalid :english
  end

  test 'source defaults to null' do
    remove_field_and_test_null_default :source
  end

  test 'cost defaults to 0' do
    remove_field_and_test_default :cost, 0
  end

  test 'platinum defaults to 0' do
    remove_field_and_test_default :platinum, 0
  end

  test 'next_price_scrape defaults to 0' do
    remove_field_and_test_default :next_price_scrape, DateTime.new(0)
  end

  test 'next_data_scrape defaults to 0' do
    remove_field_and_test_default :next_data_scrape, DateTime.new(0)
  end

  test 'endpoint must be unique' do
    Item.create!({endpoint: 'test_data', english: 'test 1'})
    assert_raises ActiveRecord::RecordInvalid do
      Item.create!({endpoint: 'test_data', english: 'test 2'})
    end
  end

  test 'english name must be unique' do
    Item.create!({endpoint: 'test_data1', english: 'test'})
    assert_raises ActiveRecord::RecordInvalid do
      Item.create!({endpoint: 'test_data2', english: 'test'})
    end
  end
end
