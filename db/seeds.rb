# frozen_string_literal: true

# IGSIGN seed data.
# Safe to re-run — all operations use find_or_create_by / find_or_initialize_by
# so they are fully idempotent.

# ---------------------------------------------------------------------------
# Account
# ---------------------------------------------------------------------------
account = Account.find_or_initialize_by(name: 'Ignition Group')

if account.new_record?
  account.assign_attributes(
    timezone: 'Johannesburg',   # ActiveSupport::TimeZone name for SAST (UTC+2)
    locale:   'en-US'
  )
  account.save!
  puts "Created account: #{account.name}"
else
  puts "Account already exists: #{account.name}"
end

# ---------------------------------------------------------------------------
# Admin user — Craig Doidge
# ---------------------------------------------------------------------------
user = User.find_or_initialize_by(email: 'craig@ignitiongroup.co.za')

if user.new_record?
  user.assign_attributes(
    first_name:    'Craig',
    last_name:     'Doidge',
    password:      'IgSign2026!',
    role:          User::ADMIN_ROLE,
    account:       account,
    confirmed_at:  Time.current   # skip email confirmation on seed
  )
  user.save!
  puts "Created admin user: #{user.email}"
else
  puts "Admin user already exists: #{user.email}"
end
