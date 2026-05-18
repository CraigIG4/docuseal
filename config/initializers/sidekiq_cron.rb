# frozen_string_literal: true

# IGSIGN — Scheduled jobs via sidekiq-cron.
# Jobs are only registered inside the Sidekiq server process so they don't
# fire in the web process or during tests.
#
# Cron expressions are UTC. ReminderCheckJob runs hourly so reminders are
# delivered within an hour of becoming due regardless of deploy timing.
Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Cron::Job.load_from_hash(
      'reminder_check' => {
        'cron'  => '0 * * * *',   # every hour on the hour (UTC)
        'class' => 'ReminderCheckJob'
      }
    )
  end
end
