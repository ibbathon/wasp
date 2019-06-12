ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/autorun'
require 'webmock/minitest'
require 'minitest/logger'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  ## Helper methods for models
  def remove_field_and_return_object object, field
    object[field] = nil
    object.save!
    return object
  end

  def remove_field_and_test_invalid object, field
    assert_raises ActiveRecord::RecordInvalid do
      remove_field_and_return_object object, field
    end
  end

  def remove_field_and_test_default object, field, default_value
    object = remove_field_and_return_object object, field
    assert_equal default_value, object[field]
  end

  def remove_field_and_test_null_default field
    object = remove_field_and_return_object object, field
    assert_nil object[field]
  end

  def modify_field_and_test_uniqueness object, dup_object, field
    dup_object[field] = object[field]
    assert_raises ActiveRecord::RecordInvalid do
      dup_object.save!
    end
  end
end
