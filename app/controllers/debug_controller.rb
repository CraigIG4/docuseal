# frozen_string_literal: true
# Temporary debug controller — remove after diagnosing the 500 error
class DebugController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  def render_test
    render plain: "Layout render OK — no error"
  rescue => e
    render plain: "ERROR: #{e.class}: #{e.message}\n\n#{e.backtrace.first(10).join("\n")}", status: 500
  end
end
