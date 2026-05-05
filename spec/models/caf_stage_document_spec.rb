# == Schema Information
#
# Table name: caf_stage_documents
#
#  id            :bigint           not null, primary key
#  document_name :string           not null
#  document_uuid :string           not null
#  internal_only :boolean          default(FALSE), not null
#  stripped      :boolean          default(FALSE), not null
#  stripped_at   :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  submission_id :bigint           not null
#
# Indexes
#
#  index_caf_stage_documents_on_submission_id                    (submission_id)
#  index_caf_stage_documents_on_submission_id_and_document_uuid  (submission_id,document_uuid) UNIQUE
#  index_caf_stage_documents_on_submission_id_and_internal_only  (submission_id,internal_only)
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
require 'rails_helper'

RSpec.describe CafStageDocument, type: :model do
  let(:user)       { create(:user) }
  let(:account)    { user.account }
  let(:template)   { create(:template, author: user, account: account) }
  let(:submission) { create(:submission, template: template, created_by_user: user) }

  subject(:doc) do
    CafStageDocument.new(
      submission: submission, document_uuid: SecureRandom.uuid,
      document_name: 'Contract Approval Form.pdf', internal_only: true
    )
  end

  # == Validations =============================================================

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires document_uuid' do
      doc.document_uuid = nil
      expect(doc).not_to be_valid
    end

    it 'requires document_name' do
      doc.document_name = nil
      expect(doc).not_to be_valid
    end

    it 'enforces unique document_uuid per submission' do
      doc.save!
      duplicate = CafStageDocument.new(submission: submission,
                                         document_uuid: doc.document_uuid,
                                         document_name: 'copy.pdf')
      expect(duplicate).not_to be_valid
    end
  end

  # == Scopes ==================================================================

  describe 'scopes' do
    before { doc.save! }

    it '.internal returns internal_only documents' do
      expect(CafStageDocument.internal).to include(doc)
    end

    it '.pending_strip returns unstripped internal docs' do
      expect(CafStageDocument.pending_strip).to include(doc)
    end

    it '.pending_strip excludes already-stripped docs' do
      doc.update!(stripped: true, stripped_at: Time.current)
      expect(CafStageDocument.pending_strip).not_to include(doc)
    end
  end

  # == #strip! =================================================================

  describe '#strip!' do
    before { doc.save! }

    it 'marks the document as stripped with a timestamp' do
      freeze_time do
        doc.strip!
        expect(doc.reload.stripped).to be(true)
        expect(doc.reload.stripped_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
