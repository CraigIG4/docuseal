# frozen_string_literal: true

class AddReminderTrackingToCafStageSubmitters < ActiveRecord::Migration[8.1]
  def change
    change_table :caf_stage_submitters, bulk: true do |t|
      # Stamped by SendSubmitterInvitationEmailJob after the invitation email
      # is delivered.  Nil means the invite has not yet been sent.
      t.datetime :invited_at

      # Timestamp of the most-recent reminder email sent by ReminderCheckJob.
      t.datetime :reminder_sent_at

      # Incremented each time a reminder is sent (0 = no reminders yet).
      # Used as the tier selector: 0→day-2, 1→day-5, 2→day-9.
      t.integer  :reminder_count, null: false, default: 0

      # Stamped when the day-14 escalation notice is sent to the requestor.
      # Nil means no escalation has occurred.
      t.datetime :escalated_at
    end

    add_index :caf_stage_submitters, :invited_at
  end
end
