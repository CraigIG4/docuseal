# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :maybe_redirect_to_setup
  skip_authorization_check

  def show
    checks = {
      db:      db_ok?,
      redis:   redis_ok?,
      sidekiq: sidekiq_ok?
    }

    status = checks.values.all? ? :ok : :service_unavailable

    render json: checks.transform_values { |v| v ? 'ok' : 'error' }, status:
  end

  private

  def db_ok?
    ActiveRecord::Base.connection.execute('SELECT 1')
    true
  rescue StandardError
    false
  end

  def redis_ok?
    Sidekiq.redis { |c| c.call('PING') }
    true
  rescue StandardError
    false
  end

  def sidekiq_ok?
    require 'sidekiq/api'
    # ProcessSet registers each running Sidekiq process in Redis.
    # With embedded mode this may briefly be 0 immediately after boot.
    Sidekiq::ProcessSet.new.size > 0
  rescue StandardError
    false
  end
end
