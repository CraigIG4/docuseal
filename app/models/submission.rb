# frozen_string_literal: true

# == Schema Information
#
# Table name: submissions
#
#  id                  :bigint           not null, primary key
#  archived_at         :datetime
#  expire_at           :datetime
#  name                :text
#  preferences         :text             not null
#  slug                :string           not null
#  source              :string           not null
#  submitters_order    :string           not null
#  template_fields     :text
#  template_schema     :text
#  template_submitters :text
#  variables           :text
#  variables_schema    :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  created_by_user_id  :bigint
#  template_id         :bigint
#
# Indexes
#
#  index_submissions_on_account_id_and_id                           (account_id,id)
#  index_submissions_on_account_id_and_template_id_and_id           (account_id,template_id,id) WHERE (archived_at IS NULL)
#  index_submissions_on_account_id_and_template_id_and_id_archived  (account_id,template_id,id) WHERE (archived_at IS NOT NULL)
#  index_submissions_on_created_by_user_id                          (created_by_user_id)
#  index_submissions_on_slug                                        (slug) UNIQUE
#  index_submissions_on_template_id                                 (template_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (template_id => templates.id)
#
class Submission < ApplicationRecord
  belongs_to :template, optional: true
  belongs_to :account
  belongs_to :created_by_user, class_name: 'User', optional: true

  has_one :search_entry, as: :record, inverse_of: :record, dependent: :destroy if SearchEntry.table_exists?

  has_many :submitters, dependent: :destroy
  has_many :submission_events, dependent: :destroy
  # IGSIGN: CAF stage engine
  has_many :caf_stages,          dependent: :destroy
  has_many :caf_stage_documents, dependent: :destroy

  attribute :preferences, :string, default: -> { {} }

  serialize :template_fields, coder: JSON
  serialize :template_schema, coder: JSON
  serialize :template_submitters, coder: JSON
  serialize :variables_schema, coder: JSON
  serialize :variables, coder: JSON
  serialize :preferences, coder: JSON

  attribute :source, :string, default: 'link'
  attribute :submitters_order, :string, default: 'random'

  attribute :slug, :string, default: -> { SecureRandom.base58(14) }

  has_one_attached :audit_trail
  has_one_attached :combined_document
  has_one_attached :merged_document
  has_one_attached :preview_merged_document

  has_many_attached :preview_documents
  has_many_attached :documents

  has_many :template_accesses, primary_key: :template_id, foreign_key: :template_id, dependent: nil, inverse_of: false

  has_many :template_schema_documents,
           ->(e) { where(uuid: (e.template_schema.presence || e.template.schema).pluck('attachment_uuid')) },
           through: :template, source: :documents_attachments

  has_many :template_schema_static_documents,
           ->(e) { where(uuid: e.template_schema.reject { |s| s['dynamic'] }.pluck('attachment_uuid')) },
           through: :template, source: :documents_attachments

  has_many :template_schema_dynamic_document_versions,
           ->(e) { where(sha1: e.template_schema.select { |s| s['dynamic'] }.pluck('dynamic_document_sha1')) },
           through: :template, source: :dynamic_document_versions

  has_many :template_schema_dynamic_document_attachments,
           through: :template_schema_dynamic_document_versions, source: :document_attachment

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :pending, lambda {
    where(expire_at: nil).or(where(expire_at: Time.current..))
                         .where(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id])
                                         .and(Submitter.arel_table[:completed_at].eq(nil))).select(1).arel.exists)
  }
  scope :completed, lambda {
    where.not(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id])
     .and(Submitter.arel_table[:completed_at].eq(nil))).select(1).arel.exists)
  }
  scope :declined, lambda {
    where(Submitter.where(Submitter.arel_table[:submission_id].eq(Submission.arel_table[:id])
     .and(Submitter.arel_table[:declined_at].not_eq(nil))).select(1).arel.exists)
  }
  scope :expired, -> { pending.where(expire_at: ..Time.current) }

  enum :source, {
    invite: 'invite',
    bulk: 'bulk',
    api: 'api',
    embed: 'embed',
    link: 'link'
  }, scope: false, prefix: true

  enum :submitters_order, {
    random: 'random',
    preserved: 'preserved'
  }, scope: false, prefix: true

  def expired?
    expire_at && expire_at <= Time.current
  end

  def schema_documents
    # IGSIGN: CAF submissions carry documents at the submission level (CAF PDF +
    # agreement) in addition to the template-level signing page.  Merge both
    # sources so the signing form can render all documents.
    return caf_mixed_schema_documents if caf_stage_documents.exists?

    return documents_attachments unless template_id?

    dynamic_count = template_schema&.count { |e| e['dynamic'] }.to_i

    if variables_schema.blank?
      if dynamic_count > 0
        if dynamic_count == template_schema.size
          template_schema_dynamic_document_attachments
        else
          template_schema_dynamic_and_static_document_attachments
        end
      else
        template_schema_documents
      end
    elsif dynamic_count > 0 && dynamic_count != template_schema.size
      template_schema_submission_dynamic_and_static_document_attachments
    else
      documents_attachments
    end
  end

  # Returns the documents this submitter is permitted to see during signing.
  #
  # Stage 1 (internal IG signatories) — all documents (CAF summary + agreement).
  # Stage 2+ (counterparty and beyond) — only documents with internal_only: false.
  # Non-CAF submissions — no filtering applied.
  def documents_for(submitter)
    return schema_documents unless caf_stage_documents.exists?

    stage = caf_stages.joins(:caf_stage_submitters)
                      .find_by(caf_stage_submitters: { submitter_id: submitter.id })

    # Stage 1 (position 0) or unrecognised submitter: full visibility.
    return schema_documents if stage.nil? || stage.position.zero?

    # Stage 2+: strip internal-only documents.
    internal_uuids = caf_stage_documents.where(internal_only: true).pluck(:document_uuid).to_set
    schema_documents.reject { |doc| internal_uuids.include?(doc.uuid) }
  end

  # Union of template-attached documents (the CAF signing page) and submission-
  # attached documents (generated CAF PDF + uploaded agreement).
  # Scoped to UUIDs present in template_schema so ordering/filtering is driven
  # by the schema, not by insertion order.
  def caf_mixed_schema_documents
    @caf_mixed_schema_documents ||= begin
      schema_uuids = (template_schema.presence || template&.schema || []).map { |e| e['attachment_uuid'] }
      return ActiveStorage::Attachment.none if schema_uuids.empty?

      tpl_scope = (template ? template.documents_attachments : ActiveStorage::Attachment.none)
                    .where(uuid: schema_uuids)
      sub_scope = documents_attachments.where(uuid: schema_uuids)

      ActiveStorage::Attachment.where(
        ActiveStorage::Attachment.arel_table[:id].in(
          tpl_scope.select(:id).arel.union(:all, sub_scope.select(:id).arel)
        )
      )
    end
  end

  def template_schema_submission_dynamic_and_static_document_attachments
    @template_schema_submission_dynamic_and_static_document_attachments ||=
      ActiveStorage::Attachment.where(
        ActiveStorage::Attachment.arel_table[:id].in(
          template_schema_static_documents.select(:id).arel.union(
            :all,
            documents_attachments.select(:id).arel
          )
        )
      )
  end

  def template_schema_dynamic_and_static_document_attachments
    @template_schema_dynamic_and_static_document_attachments ||=
      ActiveStorage::Attachment.where(
        ActiveStorage::Attachment.arel_table[:id].in(
          template_schema_static_documents.select(:id).arel.union(
            :all,
            template_schema_dynamic_document_attachments.select(:id).arel
          )
        )
      )
  end

  def fields_uuid_index
    @fields_uuid_index ||= (template_fields || template.fields).index_by { |f| f['uuid'] }
  end

  def audit_trail_url(expires_at: nil)
    return if audit_trail.blank?

    ActiveStorage::Blob.proxy_url(audit_trail.blob, expires_at:)
  end
  alias audit_log_url audit_trail_url

  def combined_document_url(expires_at: nil)
    return if combined_document.blank?

    ActiveStorage::Blob.proxy_url(combined_document.blob, expires_at:)
  end
end
