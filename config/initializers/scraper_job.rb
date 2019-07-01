Rails.application.config.after_initialize do
  $list_job_running = false
  ListScraperJob.perform_later
  DataScraperJob.perform_later
end
