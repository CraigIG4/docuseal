# frozen_string_literal: true

# == Schema Information
#
# Table name: caf_stages
#
#  id                         :bigint           not null, primary key
#  activated_at               :datetime
#  completed_at               :datetime
#  name                       :string           not null
#  position                   :integer          default(0), not null
#  routing                    :string           default("ordered"), not null
#  status                     :string           default("pending"), not null
#  strip_internal_on_complete :boolean          default(FALSE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  submission_id              :bigint           not null
#
# Indexes
#
#  index_caf_stages_on_status                      (status)
#  index_caf_stages_on_submission_id               (submission_id)
#  index_caf_stages_on_submission_id_and_position  (submission_id,position) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (submission_id => submissions.id)
#
require 'rails_helper'

RSpec.describe CafStage, type: :model do
  # DocuSeal factory chain: user owns account, template shares that account.
  # This ensures account.users.minimum(:id) is non-nil for default_template_folder.
  subject(:stage) do
    described_class.new(
      submission: submission,
      name:       'Internal CAF Approval',
      position:   0,
      routing:    'ordered',
      status:     'pending'
    )
  end

  let(:user)       { create(:user) }
  let(:account)    { user.account }
  let(:template)   { create(:template, author: user, account: account) }
  let(:submission) { create(:submission, template: template, created_by_user: user) }

  # == Validations =============================================================

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires name' do
      stage.name = nil
      expect(stage).not_to be_valid
      expect(stage.errors[:name]).to include("can't be blank")
    end

    it 'rejects invalid routing' do
      stage.routing = 'chaotic'
      expect(stage).not_to be_valid
      expect(stage.errors[:routing]).to include('is not included in the list')
    end

    it 'rejects invalid status' do
      stage.status = 'limbo'
      expect(stage).not_to be_valid
    end

    it 'enforces unique position per submission' do
      stage.save!
      duplicate = described_class.new(submission: submission, name: 'Other', position: 0,
                                      routing: 'ordered', status: 'pending')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:position]).to include('has already been taken')
    end
  end

  # == Associations ============================================================

  describe 'associations' do
    it 'has caf_stage_submitters' do
      expect(described_class.reflect_on_association(:caf_stage_submitters).macro).to eq(:has_many)
    end

    it 'has submitters through caf_stage_submitters' do
      expect(described_class.reflect_on_association(:submitters).options[:through]).to eq(:caf_stage_submitters)
    end

    it 'belongs to submission' do
      stage.save!
      expect(stage.submission).to eq(submission)
    end
  end

  # == Scopes ==================================================================

  describe 'scopes' do
    before { stage.save! }

    it '.pending returns pending stages' do
      expect(described_class.pending).to include(stage)
    end

    it '.active excludes pending stages' do
      expect(described_class.active).not_to include(stage)
    end

    it '.ordered_by_position sorts by position asc' do
      stage2 = described_class.create!(submission: submission, name: 'Stage 2',
                                       position: 1, routing: 'parallel', status: 'pending')
      expect(described_class.ordered_by_position.to_a).to eq([stage, stage2])
    end
  end

  # == State machine ===========================================================

  describe '#activate!' do
    before { stage.save! }

    it 'transitions status to active' do
      stage.activate!
      expect(stage.reload.status).to eq('active')
    end

    it 'sets activated_at' do
      freeze_time do
        stage.activate!
        expect(stage.reload.activated_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '#complete!' do
    before { stage.update!(status: 'active', activated_at: 1.minute.ago) }

    it 'transitions status to complete' do
      stage.complete!
      expect(stage.reload.status).to eq('complete')
    end

    it 'sets completed_at' do
      freeze_time do
        stage.complete!
        expect(stage.reload.completed_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when strip_internal_on_complete is true' do
      before { stage.update!(strip_internal_on_complete: true) }

      it 'marks internal documents as stripped' do
        doc = CafStageDocument.create!(
          submission: submission, document_uuid: SecureRandom.uuid,
          document_name: 'CAF.pdf', internal_only: true, stripped: false
        )
        stage.complete!
        expect(doc.reload.stripped).to be(true)
        expect(doc.reload.stripped_at).not_to be_nil
      end

      it 'does not strip external documents' do
        doc = CafStageDocument.create!(
          submission: submission, document_uuid: SecureRandom.uuid,
          document_name: 'MSA.pdf', internal_only: false, stripped: false
        )
        stage.complete!
        expect(doc.reload.stripped).to be(false)
      end
    end
  end

  describe '#all_submitters_complete?' do
    let(:submitter) do
      create(:submitter, submission: submission, account_id: account.id, uuid: SecureRandom.uuid)
    end

    before do
      stage.save!
      CafStageSubmitter.create!(caf_stage: stage, submitter: submitter,
                                role: 'CLO', position: 0)
    end

    it 'returns false when submitter has not signed' do
      expect(stage.all_submitters_complete?).to be(false)
    end

    it 'returns true when all submitters have signed' do
      submitter.update!(completed_at: Time.current)
      expect(stage.all_submitters_complete?).to be(true)
    end
  end
end
