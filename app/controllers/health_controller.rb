# frozen_string_literal: true

class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :maybe_redirect_to_setup
  skip_authorization_check

  def show
    db      = db_ok?
    redis   = redis_ok?
    sidekiq = sidekiq_ok?

    # Only a DB failure is fatal — Redis/Sidekiq degraded is still a live app.
    http_status = db ? :ok : :service_unavailable
    status_label = (db && redis && sidekiq) ? 'ok' : (db ? 'degraded' : 'error')

    render json: {
      db:      db      ? 'ok' : 'error',
      redis:   redis   ? 'ok' : 'error',
      sidekiq: sidekiq ? 'ok' : 'error',
      status:  status_label
    }, status: http_status
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
