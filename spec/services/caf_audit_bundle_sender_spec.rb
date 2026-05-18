# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CafAuditBundleSender, '#collect_signed_documents', type: :model do
  let(:account)    { create(:account) }
  let(:user)       { create(:user, account: account) }
  let(:submission) { create(:submission, created_by_user: user) }

  let(:workflow) do
    create(:caf_workflow,
           account:           account,
           created_by_user:   user,
           status:            'sent_counterparty',
           caf_submission:    submission,
           requestor_email:   user.email,
           counterparty_email: 'cp@example.com')
  end

  subject(:sender) { described_class.new(workflow) }

  describe '#collect_signed_documents' do
    context 'when submission has no caf_stage_documents' do
      it 'returns an empty array' do
        expect(sender.send(:collect_signed_documents)).to eq([])
      end
    end

    context 'when submission has only internal_only documents' do
      before do
        create(:submission_event, submission: submission)
        CafStageDocument.create!(
          submission:    submission,
          document_uuid: SecureRandom.uuid,
          document_name: 'internal_caf.pdf',
          internal_only: true
        )
      end

      it 'returns an empty array (internal docs are not attached to the audit bundle)' do
        expect(sender.send(:collect_signed_documents)).to eq([])
      end
    end

    context 'when caf has no caf_submission' do
      before { workflow.update!(caf_submission: nil) }

      it 'returns an empty array without raising' do
        expect(sender.send(:collect_signed_documents)).to eq([])
      end
    end
  end
end
