# Declarative rules table: maps document_type → required stage chain per account.
# Seed data lives in db/seeds/caf_approval_matrices.rb.
#
# stages_config is a JSONB array:
#   [{ "name": "Internal CAF Approval",
#      "routing": "ordered",
#      "required_roles": ["BU Head","Procurement","BU Finance","CLO","CFO","COO","CEO"],
#      "strip_internal_on_complete": true },
#    { "name": "Counterparty Signing",
#      "routing": "parallel",
#      "required_roles": ["counterparty"] }]
# == Schema Information
#
# Table name: caf_approval_matrices
#
#  id            :bigint           not null, primary key
#  active        :boolean          default(TRUE), not null
#  document_type :string           not null
#  stages_config :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#
# Indexes
#
#  idx_caf_approval_matrices_active_unique    (account_id,document_type) UNIQUE WHERE (active = true)
#  index_caf_approval_matrices_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class CafApprovalMatrix < ApplicationRecord
  DOCUMENT_TYPES = %w[nda contract employment other].freeze

  belongs_to :account

  validates :document_type, presence: true, inclusion: { in: DOCUMENT_TYPES }
  validates :stages_config, presence: true
  validate  :stages_config_valid

  scope :active, -> { where(active: true) }

  # Look up the active matrix for an account + document type.
  def self.for(account, document_type)
    active.find_by(account: account, document_type: document_type.to_s)
  end

  # Build (but do not save) stage records for a given submission.
  # Caller is responsible for persisting and assigning submitters.
  def build_stages_for(submission)
    stages_config.each_with_index.map do |cfg, idx|
      submission.caf_stages.build(
        name:                       cfg['name'],
        position:                   idx,
        routing:                    cfg.fetch('routing', 'ordered'),
        strip_internal_on_complete: cfg.fetch('strip_internal_on_complete', false),
        status:                     idx.zero? ? 'active' : 'pending'
      )
    end
  end

  private

  def stages_config_valid
    return unless stages_config.is_a?(Array)
    stages_config.each_with_index do |stage, idx|
      unless stage['name'].present?
        errors.add(:stages_config, "stage #{idx}: 'name' is required")
      end
      unless stage['required_roles'].is_a?(Array) && stage['required_roles'].any?
        errors.add(:stages_config, "stage #{idx}: 'required_roles' must be a non-empty array")
      end
    end
  end
end
