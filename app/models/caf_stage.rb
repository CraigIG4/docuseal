# IGSIGN — CAF Stage Engine
# A Stage is one phase of a Submission's lifecycle (e.g. "Internal CAF Approval",
# "Counterparty Signing"). Stages are ordered by :position and run sequentially.
# Each stage groups a set of Submitters (signers) with ordered or parallel routing.
# == Schema Information
#
# Table name: caf_stages
#
#  id                         :bigint           not null, primary key
#  activated_at               :datetime
#  completed_at               :datetime
#  name                       :string           not null
#  position                   :integer          default(0), not null
#  routing                    :string           default("ordered"), not null
#  status                     :string           default("pending"), not null
#  strip_internal_on_complete :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  submission_id              :bigint           not null
#
# Indexes
#
#  index_caf_stages_on_status                      (status)
#  index_caf_stages_on_submission_id               (submission_id)
#  index_caf_stages_on_submission_id_and_position  (submission_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
class CafStage < ApplicationRecord
  ROUTING_OPTIONS = %w[ordered parallel hybrid].freeze
  STATUS_OPTIONS  = %w[pending active complete skipped].freeze

  belongs_to :submission
  has_many   :caf_stage_submitters, dependent: :destroy
  has_many   :submitters, through: :caf_stage_submitters
  has_many   :caf_stage_documents, through: :submission, foreign_key: :submission_id

  validates :name,     presence: true
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :routing,  inclusion: { in: ROUTING_OPTIONS }
  validates :status,   inclusion: { in: STATUS_OPTIONS }
  validates :position, uniqueness: { scope: :submission_id }

  scope :ordered_by_position, -> { order(position: :asc) }
  scope :pending,             -> { where(status: 'pending') }
  scope :active,              -> { where(status: 'active') }
  scope :complete,            -> { where(status: 'complete') }

  # Transition: pending → active. Fires invite notifications.
  def activate!
    update!(status: 'active', activated_at: Time.current)
    case routing
    when 'ordered'  then notify_next_submitter!
    when 'parallel' then notify_all_submitters!
    when 'hybrid'   then notify_all_submitters!  # hybrid handled externally if needed
    end
  end

  # Transition: active → complete. Strips internal docs if flagged, then advances.
  def complete!
    transaction do
      update!(status: 'complete', completed_at: Time.current)
      strip_internal_documents! if strip_internal_on_complete?
      advance_to_next_stage!
    end
  end

  # True once all submitters in this stage have signed.
  def all_submitters_complete?
    submitters.all?(&:completed_at?)
  end

  # For ordered routing: the next submitter who has not yet been sent an invite.
  def next_pending_submitter
    caf_stage_submitters
      .joins(:submitter)
      .merge(Submitter.where(sent_at: nil, completed_at: nil))
      .order('caf_stage_submitters.position ASC')
      .first&.submitter
  end

  private

  def strip_internal_documents!
    CafStageDocument
      .where(submission_id: submission_id, internal_only: true, stripped: false)
      .update_all(stripped: true, stripped_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def advance_to_next_stage!
    next_stage = submission.caf_stages.pending.ordered_by_position.first
    next_stage&.activate!
  end

  def notify_next_submitter!
    submitter = next_pending_submitter
    SendSubmitterInviteJob.perform_later(submitter) if submitter
  end

  def notify_all_submitters!
    submitters.where(sent_at: nil).each do |s|
      SendSubmitterInviteJob.perform_later(s)
    end
  end
end
