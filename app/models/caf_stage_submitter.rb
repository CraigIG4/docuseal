# frozen_string_literal: true

# Join table: links a Submitter to a CafStage with an explicit role and position.
# Position controls notification order for ordered-routing stages.
# Also tracks reminder cadence so ReminderCheckJob can enforce the 2/5/9/14-day
# escalation ladder without duplicating sends across Sidekiq retries.
#
# == Schema Information
#
# Table name: caf_stage_submitters
#
#  id               :bigint           not null, primary key
#  escalated_at     :datetime
#  invited_at       :datetime
#  position         :integer          default(0), not null
#  reminder_count   :integer          default(0), not null
#  reminder_sent_at :datetime
#  role             :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  caf_stage_id     :bigint           not null
#  submitter_id     :bigint           not null
#
# Indexes
#
#  index_caf_stage_submitters_on_caf_stage_id                   (caf_stage_id)
#  index_caf_stage_submitters_on_caf_stage_id_and_position      (caf_stage_id,position)
#  index_caf_stage_submitters_on_caf_stage_id_and_submitter_id  (caf_stage_id,submitter_id) UNIQUE
#  index_caf_stage_submitters_on_invited_at                     (invited_at)
#  index_caf_stage_submitters_on_submitter_id                   (submitter_id)
#
# Foreign Keys
#
#  fk_rails_...  (caf_stage_id => caf_stages.id)
#  fk_rails_...  (submitter_id => submitters.id)
#
class CafStageSubmitter < ApplicationRecord
  belongs_to :caf_stage
  belongs_to :submitter

  validates :role, presence: true
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :submitter_id, uniqueness: { scope: :caf_stage_id }

  scope :ordered,           -> { order(position: :asc) }
  scope :pending_reminder,  -> { joins(:caf_stage).where(caf_stages: { status: 'active' }).where.not(invited_at: nil) }
  scope :not_completed,     -> { joins(:submitter).where(submitters: { completed_at: nil }) }
  scope :not_escalated,     -> { where(escalated_at: nil) }

  # Returns the CafWorkflow that owns this submitter's stage.
  def caf_workflow
    @caf_workflow ||= CafWorkflow.find_by(caf_submission_id: caf_stage.submission_id)
  end

  # True when this submitter is overdue for their next reminder tier.
  # tier_days is the number of days after invite that the tier fires.
  # tier_count is the reminder_count that should be in effect at that tier.
  def due_for_reminder?(tier_days:, tier_count:)
    invited_at.present? &&
      reminder_count == tier_count &&
      invited_at <= tier_days.days.ago
  end
end
