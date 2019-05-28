require 'test_helper'

class ScraperTasksTest < ActiveSupport::TestCase
  setup do
    require 'rake'
    Wasp::Application.load_tasks
  end

  test 'fetch_prices outputs "Hello, world" to console' do
    out, err = capture_io do
      Rake::Task['scraper:fetch_prices'].invoke
    end

    assert_equal "Hello, world\n", out
  end

  teardown do
    Rake::Task.clear
  end
end
