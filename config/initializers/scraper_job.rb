Rails.application.config.after_initialize do
  ListScraperJob.perform_later
end
