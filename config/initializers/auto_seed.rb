# frozen_string_literal: true

# Auto-seed on first boot in production.
# Runs on every process startup but exits immediately if the admin user already
# exists — safe to leave in place permanently.
#
# Race condition note: if two processes boot simultaneously both may enter the
# block. seeds.rb uses find_or_initialize_by, and the unique index on users.email
# ensures only one INSERT succeeds. The loser raises RecordNotUnique, which is
# caught below and logged.

if Rails.env.production?
  begin
    unless User.exists?(email: 'craig@ignitiongroup.co.za')
      load Rails.root.join('db/seeds.rb')
      Rails.logger.info('[AutoSeed] Seed completed')
    end
  rescue => e
    Rails.logger.error("[AutoSeed] Seed failed: #{e.message}")
  end
end
