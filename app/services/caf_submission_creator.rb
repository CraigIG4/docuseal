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
    # Validate signatories have been resolved (no placeholders without email)
    unresolved = @caf.signatories.select { |s| s['placeholder'] && s['email'].blank? }
    if unresolved.any?
      return { success: false, error: "Please assign all signatories (unresolved: #{unresolved.map { |s| s['role'] }.join(', ')})" }
    end

    # We need a template to attach the submission to.
    # Use the account's CAF template, or create a minimal one on the fly.
    template = find_or_create_caf_template

    # Create the submission via DocuSeal internals
    submission = Submission.create!(
      account:           @caf.account,
      template:          template,
      created_by_user:   @user,
      source:            'api',
      submitters_order:  'random',  # we control order via CafStage
      name:              submission_name,
    )

    # Create submitters in the CAF signing order
    @caf.signatories.each_with_index do |sig, idx|
      submission.submitters.create!(
        account:    @caf.account,
        name:       sig['name'],
        email:      sig['email'],
        uuid:       SecureRandom.uuid,
        slug:       SecureRandom.base58(14),
        metadata:   { 'caf_role' => sig['role'], 'caf_position' => idx },
      )
    end

    # Build CAF stages using the approval matrix or defaults
    matrix = CafApprovalMatrix.for(@caf.account, caf_type_for_matrix)
    if matrix
      matrix.build_stages_for(submission).each(&:save!)
    else
      build_default_stages(submission)
    end

    # Register the contract document as an external (non-stripped) document
    if @caf.contract_document.attached?
      CafStageDocument.create!(
        submission:    submission,
        document_uuid: @caf.contract_document.blob.key,
        document_name: @caf.contract_document.blob.filename.to_s,
        internal_only: false,
      )
    end

    # Activate the first stage to send the first email
    first_stage = submission.caf_stages.ordered_by_position.first
    first_stage&.activate!

    { success: true, submission: submission }
  rescue => e
    Rails.logger.error("CafSubmissionCreator failed: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    { success: false, error: e.message }
  end

  private

  def submission_name
    "CAF — #{@caf.caf_type_label} — #{@caf.contracting_party} — #{Date.current.strftime('%d %b %Y')}"
  end

  def caf_type_for_matrix
    case @caf.caf_type
    when 'nda'        then 'nda'
    when 'short_form', 'long_form' then 'contract'
    else 'other'
    end
  end

  def find_or_create_caf_template
    # Look for an existing pinned CAF template
    existing = @caf.account.templates.find_by(name: 'IGSIGN CAF Template')
    return existing if existing

    # Create a minimal blank template — the actual CAF document
    # is generated as a PDF attachment when the submission is submitted.
    Template.create!(
      account:    @caf.account,
      name:       'IGSIGN CAF Template',
      created_by: @user,
      fields:     [],
      schema:     [],
      submitters: [{ 'name' => 'Approver', 'uuid' => SecureRandom.uuid }],
    )
  end

  def build_default_stages(submission)
    # Stage 1: Internal IG approval (ordered, strip CAF on complete)
    stage1 = submission.caf_stages.create!(
      name:                       'Internal CAF Approval',
      position:                   0,
      routing:                    'ordered',
      strip_internal_on_complete: true,
      status:                     'active',
      activated_at:               Time.current,
    )

    # Assign all signatories to stage 1
    submission.submitters.order(created_at: :asc).each_with_index do |submitter, idx|
      CafStageSubmitter.create!(
        caf_stage:   stage1,
        submitter:   submitter,
        role:        submitter.metadata&.dig('caf_role') || 'Approver',
        position:    idx,
      )
    end

    # Stage 2: Counterparty signing (created later, when stage 1 completes)
    submission.caf_stages.create!(
      name:                       'Counterparty Signing',
      position:                   1,
      routing:                    'parallel',
      strip_internal_on_complete: false,
      status:                     'pending',
    )
  end
end
