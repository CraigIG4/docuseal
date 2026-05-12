# frozen_string_literal: true

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
  STATUS_OPTIONS = %w[pending active complete skipped].freeze

  belongs_to :submission
  has_many :caf_stage_submitters, dependent: :destroy
  has_many :submitters, through: :caf_stage_submitters
  has_many :caf_stage_documents, through: :submission, foreign_key: :submission_id

  validates :name, presence: true
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :routing, inclusion: { in: ROUTING_OPTIONS }
  validates :status, inclusion: { in: STATUS_OPTIONS }
  validates :position, uniqueness: { scope: :submission_id }

  scope :ordered_by_position, -> { order(position: :asc) }
  scope :pending, -> { where(status: 'pending') }
  scope :active, -> { where(status: 'active') }
  scope :complete, -> { where(status: 'complete') }

  # Transition: pending → active. Fires invite notifications.
  def activate!
    update!(status: 'active', activated_at: Time.current)
    case routing
    when 'ordered' then notify_next_submitter!
    when 'parallel', 'hybrid' then notify_all_submitters!
    end
  end

  # Transition: active → complete. Records audit marker on internal docs if
  # flagged, then advances to the next stage.
  #
  # Note: the stripped/stripped_at columns are INFORMATIONAL audit markers only.
  # Visibility filtering is enforced at query time by Submission#documents_for
  # and SubmitFormController#maybe_filter_caf_schema_for_counterparty using the
  # internal_only flag.  No PDF bytes are manipulated.
  def complete!
    transaction do
      update!(status: 'complete', completed_at: Time.current)
      record_internal_document_transition! if strip_internal_on_complete?
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

  # Sets stripped: true on all internal-only CafStageDocuments as an audit
  # marker recording when Stage 1 completed.  This does NOT remove any bytes
  # from storage — visibility is controlled by Submission#documents_for.
  def record_internal_document_transition!
    CafStageDocument
      .where(submission_id: submission_id, internal_only: true, stripped: false)
      .update_all(stripped: true, stripped_at: Time.current)
  end

  def advance_to_next_stage!
    next_stage = submission.caf_stages.pending.ordered_by_position.first
    next_stage&.activate!
  end

  def notify_next_submitter!
    submitter = next_pending_submitter
    SendSubmitterInvitationEmailJob.perform_async('submitter_id' => submitter.id) if submitter
  end

  def notify_all_submitters!
    submitters.where(sent_at: nil).each do |s|
      SendSubmitterInvitationEmailJob.perform_async('submitter_id' => s.id)
    end
  end
end
