# frozen_string_literal: true

# IGSIGN — Creates a DocuSeal Submission for the internal CAF signing phase.
# After all IG signatories complete, the CafCompletionHandler fires to strip
# the CAF and create the counterparty submission.
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
    attach_contract_document(submission)

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

  def attach_contract_document(submission)
    return unless @caf.contract_document.attached?

    CafStageDocument.create!(
      submission: submission,
      document_uuid: @caf.contract_document.blob.key,
      document_name: @caf.contract_document.blob.filename.to_s,
      internal_only: false
    )
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
end
