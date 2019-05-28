require 'minitest/autorun'

class WheneverTest < ActiveSupport::TestCase
  setup do
    load 'Rakefile'
  end

  test 'rake statements exist' do
    schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')

    assert_equal schedule.jobs[:rake].length, 2, \
      'Expected schedule to include two rake tasks'
    schedule.jobs[:rake].each do |t|
      assert Rake::Task.task_defined?(t[:task]), \
        "Expected rake task #{t[:task]} to be defined"
    end
  end

  test 'prices scraper is registered in hour basis' do
    schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
    prices_task = schedule.jobs[:rake].detect do |t|
      t[:task] == 'scraper:fetch_prices'
    end

    refute_nil prices_task, \
      'Expected prices scraper task to be scheduled'
    assert_equal [:hour], prices_task[:every], \
      'Expected prices scraper task to be scheduled hourly'
  end

  test 'items scraper is registered in day basis' do
    schedule = Whenever::Test::Schedule.new(file: 'config/schedule.rb')
    items_task = schedule.jobs[:rake].detect do |t|
      t[:task] == 'scraper:fetch_items'
    end

    refute_nil items_task, \
      'Expected items scraper task to be scheduled'
    assert_equal [:day], items_task[:every], \
      'Expected items scraper task to be scheduled daily'
  end
end
