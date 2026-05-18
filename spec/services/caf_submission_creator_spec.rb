# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CafSubmissionCreator, type: :model do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }

  # ── Bug 5: raises when no stages are built ──────────────────────────────────

  describe '#call — empty stages_config guard' do
    let(:workflow) do
      create(:caf_workflow,
             account:            account,
             created_by_user:    user,
             agreement_type:     'msa',
             counterparty_email: 'cp@example.com',
             status:             'draft')
    end

    before do
      # Stub CafApprovalMatrix.for to return nil (no matrix found)
      allow(CafApprovalMatrix).to receive(:for).and_return(nil)

      # Stub build_default_stages to produce no stages (simulates empty stages_config)
      allow_any_instance_of(described_class).to receive(:build_default_stages)

      # Stub PDF generation to avoid LibreOffice dependency
      allow_any_instance_of(CafPdfGenerator).to receive(:generate).and_return(nil)
      allow_any_instance_of(described_class).to receive(:attach_caf_pdf_document)
      allow_any_instance_of(described_class).to receive(:attach_contract_document)
      allow_any_instance_of(described_class).to receive(:merge_agreement_template_fields!)
      allow_any_instance_of(described_class).to receive(:extend_submission_schema)

      # Stub template lookup
      caf_tpl = create(:template, account: account)
      allow(account.templates).to receive(:find_by).with(name: 'IGSIGN CAF Template').and_return(caf_tpl)
    end

    it 'returns an error hash instead of raising uncaught' do
      result = described_class.new(workflow, user).call

      expect(result[:success]).to be false
      expect(result[:error]).to match(/No approval stages/i)
    end
  end
end
