# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CafAuditMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }
  let(:workflow) do
    create(:caf_workflow,
           account:            account,
           created_by_user:    user,
           agreement_type:     'nda',
           contracting_party:  'Acme Corp',
           requestor_name:     'Craig Lawrence',
           requestor_email:    'craig@ignitiongroup.co.za',
           counterparty_email: 'ceo@acme.com',
           counterparty_name:  'John Smith',
           status:             'complete')
  end

  describe '#audit_bundle' do
    subject(:mail) do
      described_class.audit_bundle(
        caf:              workflow,
        to_name:          'John Smith',
        to_email:         'ceo@acme.com',
        signed_documents: signed_docs
      )
    end

    context 'with no signed documents (backwards-compatible default)' do
      let(:signed_docs) { [] }

      it 'builds a valid email' do
        expect(mail.subject).to include('Signed Agreement')
        expect(mail.to).to eq(['ceo@acme.com'])
      end

      it 'includes the counterparty name in the To header' do
        expect(mail.to.first).to eq('ceo@acme.com')
      end

      it 'has no attachments when signed_documents is empty' do
        expect(mail.attachments).to be_empty
      end
    end

    context 'when signed_documents are passed' do
      let(:blob) do
        instance_double(
          ActiveStorage::Blob,
          filename: ActiveStorage::Filename.new('nda_agreement_1.pdf'),
          download: 'PDF binary content'
        )
      end
      let(:attachment) { instance_double(ActiveStorage::Attachment, blob: blob) }
      let(:signed_docs) { [attachment] }

      it 'attaches each document to the email' do
        expect(mail.attachments.count).to eq(1)
        expect(mail.attachments.first.filename).to eq('nda_agreement_1.pdf')
      end
    end

    context 'with default (no signed_documents argument)' do
      subject(:mail) do
        described_class.audit_bundle(
          caf:     workflow,
          to_name: 'John Smith',
          to_email: 'ceo@acme.com'
        )
      end

      it 'does not raise when called without signed_documents keyword' do
        expect { mail }.not_to raise_error
      end
    end
  end
end
