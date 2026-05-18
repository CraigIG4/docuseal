# frozen_string_literal: true

# IGSIGN — Hourly job that enforces the reminder and escalation ladder.
#
# Tiers (measured from invited_at):
#   Day  2 — first friendly reminder  (reminder_count 0 → 1)
#   Day  5 — firmer reminder          (reminder_count 1 → 2)
#   Day  9 — urgent reminder          (reminder_count 2 → 3)
#   Day 14 — escalation to requestor  (escalated_at stamped, no count change)
#
# Idempotency: each tier checks reminder_count so re-queuing after a crash
# cannot double-send a tier.  Escalation uses a nil-guard on escalated_at.
class ReminderCheckJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 3

  REMINDER_TIERS = [
    { tier_days: 2,  tier_count: 0 },
    { tier_days: 5,  tier_count: 1 },
    { tier_days: 9,  tier_count: 2 }
  ].freeze
  ESCALATION_THRESHOLD_DAYS = 14

  def perform
    Rails.logger.info('[ReminderCheckJob] Starting reminder sweep')
    process_reminder_tiers
    process_escalations
    Rails.logger.info('[ReminderCheckJob] Sweep complete')
  end

  private

  # Returns the base scope for candidates: active stage, invite sent, not signed.
  # pending_reminder — joins stage, requires status='active' and invited_at present.
  # not_completed    — joins submitter, requires completed_at nil.
  def candidates
    CafStageSubmitter
      .pending_reminder
      .not_completed
      .includes(:submitter, caf_stage: :submission)
  end

  def process_reminder_tiers
    REMINDER_TIERS.each do |tier|
      scope = candidates.where(reminder_count: tier[:tier_count])
                        .where('invited_at <= ?', tier[:tier_days].days.ago)

      scope.find_each do |css|
        send_reminder(css, tier[:tier_days])
      rescue StandardError => e
        Rails.logger.error(
          "[ReminderCheckJob] Reminder tier #{tier[:tier_days]} failed for " \
          "CafStageSubmitter #{css.id}: #{e.message}"
        )
      end
    end
  end

  def process_escalations
    scope = candidates.not_escalated
                      .where('invited_at <= ?', ESCALATION_THRESHOLD_DAYS.days.ago)

    scope.find_each do |css|
      send_escalation(css)
    rescue StandardError => e
      Rails.logger.error(
        "[ReminderCheckJob] Escalation failed for CafStageSubmitter #{css.id}: #{e.message}"
      )
    end
  end

  def send_reminder(css, days_outstanding)
    ReminderMailer.signing_reminder(css, days_outstanding).deliver_later
    css.update_columns(
      reminder_count:   css.reminder_count + 1,
      reminder_sent_at: Time.current
    )
    Rails.logger.info(
      "[ReminderCheckJob] Day-#{days_outstanding} reminder sent to " \
      "submitter #{css.submitter_id} (CafStageSubmitter #{css.id})"
    )
  end

  def send_escalation(css)
    ReminderMailer.escalation_notice(css).deliver_later
    css.update_columns(escalated_at: Time.current)
    Rails.logger.info(
      "[ReminderCheckJob] Day-#{ESCALATION_THRESHOLD_DAYS} escalation sent for " \
      "CafStageSubmitter #{css.id}"
    )
  end
end
