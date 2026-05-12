# frozen_string_literal: true

# IGSIGN — Creates a DocuSeal Submission for the internal CAF signing phase.
#
# Document model:
#   Each CAF submission carries two types of documents, tracked in CafStageDocument:
#
#   1. CAF summary PDF (internal_only: true)
#      Generated from CafPdfGenerator.  Stage 1 signatories see it; the
#      counterparty never does.  The record is preserved for audit.
#
#   2. Uploaded agreement (internal_only: false)
#      The contract being executed.  Visible to all stages.
#
#   At Stage 1 → Stage 2 transition, CafStage#complete! sets stripped: true on
#   internal_only documents as an informational audit marker.  Visibility
#   filtering is enforced by Submission#documents_for(submitter) and
#   SubmitFormController (schema override).
#
# After all IG signatories complete, CafCompletionHandler fires to activate
# Stage 2 (counterparty).
class CafSubmissionCreator
  def initialize(caf, initiated_by_user)
    @caf  = caf
    @user = initiated_by_user
  end

  def call
    unresolved = unresolved_signatories
    if unresolved.any?
      unresolved_roles = unresolved.pluck('role').join(', ')
      return { success: false, error: "Please assign all signatories (unresolved: #{unresolved_roles})" }
    end

    submission = build_submission
    attach_signatories(submission)
    attach_stages(submission)
    attach_caf_pdf_document(submission)
    attach_contract_document(submission)
    extend_submission_schema(submission)

    submission.caf_stages.ordered_by_position.first&.activate!

    { success: true, submission: submission }
  rescue StandardError => e
    Rails.logger.error("CafSubmissionCreator failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    { success: false, error: e.message }
  end

  private

  def unresolved_signatories
    @caf.signatories.select { |s| s['placeholder'] && s['email'].blank? }
  end

  def build_submission
    template = find_or_create_caf_template

    Submission.create!(
      account: @caf.account,
      template: template,
      created_by_user: @user,
      source: 'api',
      submitters_order: 'random',
      name: submission_name
    )
  end

  def attach_signatories(submission)
    @caf.signatories.each_with_index do |sig, idx|
      submission.submitters.create!(
        account: @caf.account,
        name: sig['name'],
        email: sig['email'],
        uuid: SecureRandom.uuid,
        slug: SecureRandom.base58(14),
        metadata: { 'caf_role' => sig['role'], 'caf_position' => idx }
      )
    end
  end

  def attach_stages(submission)
    matrix = CafApprovalMatrix.for(@caf.account, caf_type_for_matrix)
    if matrix
      matrix.build_stages_for(submission).each(&:save!)
    else
      build_default_stages(submission)
    end
  end

  # Generates the CAF summary PDF and attaches it to the submission as an
  # internal-only document.  Failures are logged and swallowed — the
  # signing flow proceeds even if LibreOffice is unavailable.
  def attach_caf_pdf_document(submission)
    pdf_path = nil
    pdf_path = CafPdfGenerator.new(@caf).generate

    blob = ActiveStorage::Blob.create_and_upload!(
      io:           File.open(pdf_path),
      filename:     "caf_#{@caf.id}_summary.pdf",
      content_type: 'application/pdf'
    )
    submission.documents.attach(blob)
    attachment = ActiveStorage::Attachment.find_by!(
      record_type: 'Submission', record_id: submission.id,
      name: 'documents', blob_id: blob.id
    )

    CafStageDocument.create!(
      submission:    submission,
      document_uuid: attachment.uuid,
      document_name: blob.filename.to_s,
      internal_only: true
    )

    process_document_async(attachment)
  rescue StandardError => e
    Rails.logger.error("[CafSubmissionCreator] CAF PDF generation failed for #{@caf.id}: #{e.message}")
  ensure
    File.delete(pdf_path) if pdf_path && File.exist?(pdf_path)
  end

  # Attaches the uploaded agreement to the submission and registers it as an
  # externally-visible document (internal_only: false).
  def attach_contract_document(submission)
    return unless @caf.contract_document.attached?

    blob = @caf.contract_document.blob
    submission.documents.attach(blob)
    attachment = ActiveStorage::Attachment.find_by!(
      record_type: 'Submission', record_id: submission.id,
      name: 'documents', blob_id: blob.id
    )

    CafStageDocument.create!(
      submission:    submission,
      document_uuid: attachment.uuid,
      document_name: blob.filename.to_s,
      internal_only: false
    )
  end

  # Snapshots the submission's document schema so the signing form can resolve
  # all documents — both the template's signing page and the submission-level
  # attachments (CAF summary + agreement).
  #
  # Extends the base template schema with one entry per submission-level
  # document, then persists to submission.template_schema.
  def extend_submission_schema(submission)
    base_schema = submission.template&.schema || []
    existing_uuids = base_schema.map { |item| item['attachment_uuid'] }.to_set

    new_items = submission.documents_attachments.reject { |a| existing_uuids.include?(a.uuid) }.map do |att|
      { 'attachment_uuid' => att.uuid, 'name' => att.blob.filename.base }
    end

    return if new_items.empty?

    submission.update!(template_schema: base_schema + new_items)
  end

  def submission_name
    "CAF — #{@caf.caf_type_label} — #{@caf.contracting_party} — #{Date.current.strftime('%d %b %Y')}"
  end

  def caf_type_for_matrix
    case @caf.caf_type
    when 'nda'                      then 'nda'
    when 'short_form', 'long_form'  then 'contract'
    else                                 'other'
    end
  end

  def find_or_create_caf_template
    existing = @caf.account.templates.find_by(name: 'IGSIGN CAF Template')
    return existing if existing

    Template.create!(
      account: @caf.account,
      name: 'IGSIGN CAF Template',
      author: @user,
      fields: [],
      schema: [],
      submitters: [{ 'name' => 'Approver', 'uuid' => SecureRandom.uuid }]
    )
  end

  def build_default_stages(submission)
    stage1 = create_internal_stage(submission)
    assign_submitters_to_stage(submission, stage1)
    create_counterparty_stage(submission)
  end

  def create_internal_stage(submission)
    submission.caf_stages.create!(
      name: 'Internal CAF Approval',
      position: 0,
      routing: 'ordered',
      strip_internal_on_complete: true,
      status: 'active',
      activated_at: Time.current
    )
  end

  def assign_submitters_to_stage(submission, stage)
    submission.submitters.order(created_at: :asc).each_with_index do |submitter, idx|
      CafStageSubmitter.create!(
        caf_stage: stage,
        submitter: submitter,
        role: submitter.metadata&.dig('caf_role') || 'Approver',
        position: idx
      )
    end
  end

  def create_counterparty_stage(submission)
    submission.caf_stages.create!(
      name: 'Counterparty Signing',
      position: 1,
      routing: 'parallel',
      strip_internal_on_complete: false,
      status: 'pending'
    )
  end

  def process_document_async(attachment)
    Templates::ProcessDocument.call(attachment, attachment.download)
  rescue StandardError => e
    Rails.logger.warn("[CafSubmissionCreator] ProcessDocument skipped: #{e.message.truncate(120)}")
  end
end
