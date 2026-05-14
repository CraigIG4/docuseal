# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                    :bigint           not null, primary key
#  address               :text
#  agreements_count      :integer          default(0), not null
#  country               :string           default("ZA"), not null
#  domain                :string
#  name                  :string           not null
#  primary_contact_email :string
#  primary_contact_name  :string
#  registration_number   :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#
# Indexes
#
#  index_companies_on_account_id             (account_id)
#  index_companies_on_account_id_and_domain  (account_id,domain)
#  index_companies_on_account_id_and_name    (account_id,name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Company < ApplicationRecord
  belongs_to :account
  has_many :caf_workflows, dependent: :nullify
  has_many :company_signatories, dependent: :destroy

  validates :name, presence: true
  validates :primary_contact_email,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            allow_blank: true

  scope :alphabetical, -> { order(name: :asc) }
  scope :search, lambda { |q|
    term = "%#{q.to_s.downcase.strip}%"
    where(
      'lower(name) LIKE ? OR lower(domain) LIKE ? OR lower(primary_contact_name) LIKE ?',
      term, term, term
    )
  }

  def display_name
    domain.present? ? "#{name} (#{domain})" : name
  end

  def sync_agreements_count!
    update_column(:agreements_count, caf_workflows.count)
  end

  # ── Signatory memory ──────────────────────────────────────────────────────

  # Find or create a CompanySignatory record for the given email.
  # Increments times_signed and updates last_seen_at each time.
  # Safe to call multiple times for the same person.
  def record_signatory!(name, email, workflow_id: nil)
    return unless email.present?

    sig = company_signatories.find_or_initialize_by(email: email.strip.downcase)
    sig.name          = name.presence || sig.name || email
    sig.times_signed  = sig.times_signed.to_i + 1
    sig.last_seen_at  = Time.current
    sig.first_seen_at ||= Time.current
    sig.last_workflow_id = workflow_id if workflow_id
    sig.active = true
    sig.save!
    sig
  end

  # Active signatories ordered by recency then frequency.
  def recent_signatories(limit: 5)
    company_signatories.active.recent_first.limit(limit)
  end

  # Returns the single signatory if they appear in all three most-recent
  # workflows for this company.  Nil if there are multiple or none.
  def smart_default_signatory
    recent = company_signatories.active.recent_first.limit(3).to_a
    return recent.first if recent.one?

    nil
  end
end
