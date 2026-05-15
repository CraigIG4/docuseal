# frozen_string_literal: true

# Append-only audit log for approval matrix lifecycle events.
# Created separately from SubmissionEvent because that table requires
# submission_id NOT NULL and matrix events are not tied to any submission.
#
# == Schema Information
#
# Table name: matrix_audit_events
#
#  id                      :bigint           not null, primary key
#  account_id              :bigint           not null
#  user_id                 :bigint           (null = system/seed)
#  caf_approval_matrix_id  :bigint           not null
#  event_type              :string           not null
#  data                    :jsonb            default({}), not null
#  created_at              :datetime         not null
#
class MatrixAuditEvent < ApplicationRecord
  self.ignored_columns = [] # no updated_at — this is append-only

  belongs_to :account
  belongs_to :caf_approval_matrix
  belongs_to :user, optional: true

  validates :event_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_matrix, ->(matrix) { where(caf_approval_matrix: matrix) }
end
