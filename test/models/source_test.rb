require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  setup do
    @data = {
      endpoint: 'test_source',
      english: 'Test Source',
    }
  end

  def remove_field_and_return_item field
    @data.delete(field)
    return Source.create!(@data)
  end

  def remove_field_and_test_invalid field
    assert_raises ActiveRecord::RecordInvalid do
      remove_field_and_return_item field
    end
  end

  test 'endpoint is required' do
    remove_field_and_test_invalid :endpoint
  end

  test 'english is required' do
    remove_field_and_test_invalid :english
  end
end
