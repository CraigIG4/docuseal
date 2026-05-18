# frozen_string_literal: true

# IGSIGN — production startup checks.
# Fail fast on missing security-critical environment variables so a
# misconfigured deploy surfaces immediately rather than silently accepting
# unauthenticated webhook traffic.
Rails.application.config.after_initialize do
  next unless Rails.env.production?

  if ENV['INTERNAL_WEBHOOK_SECRET'].blank?
    raise 'IGSIGN startup check failed: INTERNAL_WEBHOOK_SECRET must be set in production. ' \
          'Generate a strong random value (openssl rand -hex 32) and set it as an environment variable.'
  end
end
