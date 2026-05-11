# frozen_string_literal: true

# Tracks per-submission document metadata for the CAF engine.
# internal_only: true means this document (e.g. the CAF itself) is stripped
# from the outgoing manifest before external signing stages begin.
# == Schema Information
#
# Table name: caf_stage_documents
#
#  id            :bigint           not null, primary key
#  document_name :string           not null
#  document_uuid :string           not null
#  internal_only :boolean          default(FALSE), not null
#  stripped      :boolean          default(FALSE), not null
#  stripped_at   :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  submission_id :bigint           not null
#
# Indexes
#
#  index_caf_stage_documents_on_submission_id                    (submission_id)
#  index_caf_stage_documents_on_submission_id_and_document_uuid  (submission_id,document_uuid) UNIQUE
#  index_caf_stage_documents_on_submission_id_and_internal_only  (submission_id,internal_only)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
class CafStageDocument < ApplicationRecord
  belongs_to :submission

  validates :document_uuid, presence: true
  validates :document_name, presence: true
  validates :document_uuid, uniqueness: { scope: :submission_id }

  scope :internal, -> { where(internal_only: true) }
  scope :external, -> { where(internal_only: false) }
  scope :stripped, -> { where(stripped: true) }
  scope :pending_strip, -> { where(internal_only: true, stripped: false) }

  def strip!
    update!(stripped: true, stripped_at: Time.current)
  end
end
