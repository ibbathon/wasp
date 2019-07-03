Rails.application.config.after_initialize do
  $list_job_running = false
  # Don't kick off the jobs when in the console
  if Rails.const_defined? 'Server'
    ListScraperJob.perform_later
    DataScraperJob.perform_later
    PriceScraperJob.perform_later
  end
end
