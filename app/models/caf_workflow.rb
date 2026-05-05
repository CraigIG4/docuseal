# frozen_string_literal: true
# IGSIGN — Contract Approval Form Workflow
# Stores metadata for the full CAF lifecycle:
#   draft → pending_ig → ig_complete → sent_counterparty → complete
# == Schema Information
#
# Table name: caf_workflows
#
#  id                     :bigint           not null, primary key
#  caf_type               :string           not null
#  contracting_party      :string
#  counterparty_email     :string
#  counterparty_name      :string
#  entity                 :string           not null
#  high_level_summary     :text
#  ignition_company       :string
#  long_form_data         :jsonb
#  mandate_description    :text
#  requestor_email        :string
#  requestor_name         :string
#  signatories            :jsonb
#  status                 :string           default("draft"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  caf_submission_id      :bigint
#  contract_submission_id :bigint
#  created_by_user_id     :bigint           not null
#
# Indexes
#
#  index_caf_workflows_on_account_id                 (account_id)
#  index_caf_workflows_on_account_id_and_created_at  (account_id,created_at)
#  index_caf_workflows_on_account_id_and_status      (account_id,status)
#  index_caf_workflows_on_caf_submission_id          (caf_submission_id)
#  index_caf_workflows_on_contract_submission_id     (contract_submission_id)
#  index_caf_workflows_on_created_by_user_id         (created_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (caf_submission_id => submissions.id)
#  fk_rails_...  (contract_submission_id => submissions.id)
#  fk_rails_...  (created_by_user_id => users.id)
#
class CafWorkflow < ApplicationRecord
  TYPES    = %w[nda short_form long_form].freeze
  STATUSES = %w[draft pending_ig ig_complete sent_counterparty complete cancelled].freeze

  belongs_to :account
  belongs_to :created_by_user, class_name: 'User'
  belongs_to :caf_submission,      class_name: 'Submission', optional: true
  belongs_to :contract_submission, class_name: 'Submission', optional: true

  has_one_attached :contract_document

  validates :entity,    presence: true, inclusion: { in: IgSignatories::ENTITIES.keys.map(&:to_s) }
  validates :caf_type,  presence: true, inclusion: { in: TYPES }
  validates :status,    presence: true, inclusion: { in: STATUSES }
  validates :counterparty_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true


  scope :active,    -> { where.not(status: %w[complete cancelled]) }
  scope :pending,   -> { where(status: %w[pending_ig sent_counterparty]) }
  scope :complete,  -> { where(status: 'complete') }
  scope :recent,    -> { order(created_at: :desc) }

  def entity_name
    IgSignatories.entity_name(entity)
  end

  def caf_type_label
    { 'nda' => 'NDA', 'short_form' => 'Short Form CAF', 'long_form' => 'Long Form CAF' }.fetch(caf_type, caf_type)
  end

  def status_label
    {
      'draft'              => 'Draft',
      'pending_ig'         => 'Pending IG Approval',
      'ig_complete'        => 'IG Approved',
      'sent_counterparty'  => 'Sent to Counterparty',
      'complete'           => 'Complete',
      'cancelled'          => 'Cancelled',
    }.fetch(status, status.humanize)
  end

  def status_badge_class
    case status
    when 'draft'             then 'badge-neutral'
    when 'pending_ig'        then 'badge-warning'
    when 'ig_complete'       then 'badge-info'
    when 'sent_counterparty' then 'badge-primary'
    when 'complete'          then 'badge-success'
    when 'cancelled'         then 'badge-error'
    else 'badge-ghost'
    end
  end

  # Populate signatories from IgSignatories routing logic
  def auto_assign_signatories!
    chain = IgSignatories.chain_for(caf_type, entity)
    self.signatories = chain.map.with_index do |entry, idx|
      {
        'position'    => idx,
        'role'        => entry[:role],
        'name'        => entry[:name],
        'email'       => entry[:email],
        'placeholder' => entry[:placeholder] || false,
        'key'         => entry[:key].to_s,
      }
    end
  end

  def pending_ig?   = status == 'pending_ig'
  def ig_complete?  = status == 'ig_complete'
  def complete?     = status == 'complete'
  def draft?        = status == 'draft'
end
