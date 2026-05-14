# frozen_string_literal: true

# == Schema Information
#
# Table name: company_signatories
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(TRUE), not null
#  authority_basis  :text
#  email            :string           not null
#  first_seen_at    :datetime
#  last_seen_at     :datetime
#  name             :string           not null
#  phone            :string
#  role_title       :string
#  times_signed     :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :bigint           not null
#  last_workflow_id :bigint
#
# Indexes
#
#  index_company_signatories_on_company_id            (company_id)
#  index_company_signatories_on_company_id_and_email  (company_id,email) UNIQUE
#  index_company_signatories_on_last_workflow_id      (last_workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (last_workflow_id => caf_workflows.id)
#
class CompanySignatory < ApplicationRecord
  belongs_to :company
  belongs_to :last_workflow, class_name: 'CafWorkflow', optional: true

  validates :name,  presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :company_id, case_sensitive: false,
                                  message: 'is already recorded for this company' }

  scope :active,       -> { where(active: true) }
  scope :inactive,     -> { where(active: false) }
  scope :recent_first, -> { order(last_seen_at: :desc, times_signed: :desc) }

  # ── Presentation helpers ─────────────────────────────────────────────────

  def days_since_last_sign
    return nil unless last_seen_at

    ((Time.current - last_seen_at) / 1.day).round
  end

  def last_seen_label
    return 'Never signed' unless last_seen_at

    days = days_since_last_sign
    case days
    when 0 then 'Today'
    when 1 then 'Yesterday'
    else        "#{days} days ago"
    end
  end

  def authority_on_file?
    authority_basis.present?
  end
end
