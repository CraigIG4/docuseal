require 'rails_helper'

RSpec.describe CafApprovalMatrix, type: :model do
  let(:user)    { create(:user) }
  let(:account) { user.account }

  let(:valid_stages_config) do
    [
      { 'name' => 'Internal CAF Approval', 'routing' => 'ordered',
        'required_roles' => ['BU Head', 'CLO', 'CFO', 'COO', 'CEO'],
        'strip_internal_on_complete' => true },
      { 'name' => 'Counterparty Signing', 'routing' => 'parallel',
        'required_roles' => ['counterparty'] }
    ]
  end

  subject(:matrix) do
    CafApprovalMatrix.new(
      account: account, document_type: 'contract',
      stages_config: valid_stages_config, active: true
    )
  end

  # == Validations =============================================================

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'rejects unknown document_type' do
      matrix.document_type = 'partnership_deed'
      expect(matrix).not_to be_valid
      expect(matrix.errors[:document_type]).to include('is not included in the list')
    end

    it 'requires stages_config' do
      matrix.stages_config = nil
      expect(matrix).not_to be_valid
    end

    it 'rejects stage without name' do
      matrix.stages_config = [{ 'routing' => 'ordered', 'required_roles' => ['CLO'] }]
      expect(matrix).not_to be_valid
      expect(matrix.errors[:stages_config].join).to include("'name' is required")
    end

    it 'rejects stage with empty required_roles' do
      matrix.stages_config = [{ 'name' => 'Stage', 'routing' => 'ordered', 'required_roles' => [] }]
      expect(matrix).not_to be_valid
      expect(matrix.errors[:stages_config].join).to include("'required_roles'")
    end
  end

  # == .for ====================================================================

  describe '.for' do
    before { matrix.save! }

    it 'finds an active matrix by account and document_type' do
      expect(CafApprovalMatrix.for(account, 'contract')).to eq(matrix)
    end

    it 'returns nil for an inactive matrix' do
      matrix.update!(active: false)
      expect(CafApprovalMatrix.for(account, 'contract')).to be_nil
    end
  end

  # == #build_stages_for =======================================================

  describe '#build_stages_for' do
    let(:template)   { create(:template, author: user, account: account) }
    let(:submission) { create(:submission, template: template, created_by_user: user) }

    it 'returns the correct number of stage objects' do
      expect(matrix.build_stages_for(submission).length).to eq(valid_stages_config.length)
    end

    it 'sets the first stage to active' do
      stages = matrix.build_stages_for(submission)
      expect(stages.first.status).to eq('active')
    end

    it 'sets subsequent stages to pending' do
      stages = matrix.build_stages_for(submission)
      expect(stages[1..].map(&:status)).to all(eq('pending'))
    end

    it 'sets strip_internal_on_complete from config' do
      stages = matrix.build_stages_for(submission)
      expect(stages.first.strip_internal_on_complete).to be(true)
      expect(stages.last.strip_internal_on_complete).to be(false)
    end

    it 'sets positions incrementally' do
      stages = matrix.build_stages_for(submission)
      expect(stages.map(&:position)).to eq([0, 1])
    end
  end
end