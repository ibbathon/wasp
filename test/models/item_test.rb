require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  setup do
    @item = Item.find_by(endpoint: 'freeze_force')
    @dup_item = Item.find_by(endpoint: 'ember_prime_chassis')
  end

  test 'endpoint is required' do
    remove_field_and_test_invalid @item, :endpoint
  end

  test 'english is required' do
    remove_field_and_test_invalid @item, :english
  end

  test 'cost defaults to 0' do
    remove_field_and_test_default @item, :cost, 0
  end

  test 'platinum defaults to 0' do
    remove_field_and_test_default @item, :platinum, 0
  end

  test 'next_price_scrape defaults to 0' do
    remove_field_and_test_default @item, :next_price_scrape, DateTime.new(0)
  end

  test 'next_data_scrape defaults to 0' do
    remove_field_and_test_default @item, :next_data_scrape, DateTime.new(0)
  end

  test 'endpoint must be unique' do
    modify_field_and_test_uniqueness @item, @dup_item, :endpoint
  end

  test 'english name must be unique' do
    modify_field_and_test_uniqueness @item, @dup_item, :english
  end
end
