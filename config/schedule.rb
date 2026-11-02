# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "log/cron.log"
set :environment, "production"

# --- SLA Management ---
# Periodically check for breached SLAs and trigger notifications
every 5.minutes do
  runner "SlaCheckWorker.perform_async"
end

# --- Maintenance ---
# Reset usage limits for accounts (if applicable)
every 1.day, at: "12:00 am" do
  runner "UsageResetWorker.perform_async"
end

# Update exchange rates for billing (if using multi-currency)
every 1.day, at: "1:00 am" do
  runner "ExchangeRatesUpdaterWorker.perform_async"
end

# Send billing and trial reminders
every 1.day, at: "1:30 am" do
  runner "BillingRemindersWorker.perform_async"
end

# Prune old system logs to free up database space
every 1.day, at: "4:00 am" do
  runner "SystemLogsPruningWorker.perform_async"
end

# Clear expired trials
every 1.day, at: "2:00 am" do
  runner "TrialExpirationWorker.perform_async"
end

# Renew active subscriptions and process cancellations
every 1.day, at: "12:30 am" do
  runner "SubscriptionRenewalWorker.perform_async"
end

# --- Automations ---
# Evaluate time-trigger automations (e.g., "hours since last activity > 24")
every 1.hour do
  runner "Automations::TimeTriggerWorker.perform_async"
end

# Clean up automation execution logs older than 90 days
every 1.day, at: "3:00 am" do
  runner "Automations::ExecutionCleanupWorker.perform_async"
end

# --- Integrations & Channels ---
# Poll IMAP servers for incoming emails for active email channels
every 2.minutes do
  runner "ImapFetchWorker.perform_async"
end
