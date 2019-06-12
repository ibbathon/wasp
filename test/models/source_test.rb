require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  setup do
    @source = Source.find_by(english: 'Cephalon Suda')
    @dup_source = Source.find_by(english: 'Red Veil')
  end

  test 'english name is required' do
    remove_field_and_test_invalid @source, :english
  end

  test 'english name must be unique' do
    modify_field_and_test_uniqueness @source, @dup_source, :english
  end
end
