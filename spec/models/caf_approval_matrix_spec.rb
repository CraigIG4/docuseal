# frozen_string_literal: true

# == Schema Information
#
# Table name: caf_approval_matrices
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE), not null
#  agreement_types :jsonb            default([]), not null
#  document_type   :string           (legacy, nullable)
#  entity_scope    :jsonb
#  name            :string           not null
#  stages_config   :jsonb            default([]), not null
#  value_threshold :decimal(15, 2)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#
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
    build(:caf_approval_matrix,
          account:         account,
          name:            'Test NDA Matrix',
          agreement_types: ['nda'],
          stages_config:   valid_stages_config)
  end

  # ── Validations ──────────────────────────────────────────────────────────────

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires name' do
      matrix.name = nil
      expect(matrix).not_to be_valid
      expect(matrix.errors[:name]).to be_present
    end

    it 'requires at least one agreement_type' do
      matrix.agreement_types = []
      expect(matrix).not_to be_valid
      expect(matrix.errors[:agreement_types]).to be_present
    end

    it 'rejects unknown agreement_types' do
      matrix.agreement_types = ['nda', 'galactic_treaty']
      expect(matrix).not_to be_valid
      expect(matrix.errors[:agreement_types].first).to match(/unknown types/)
    end

    it 'rejects unknown entity_scope values' do
      matrix.entity_scope = ['hogwarts']
      expect(matrix).not_to be_valid
      expect(matrix.errors[:entity_scope].first).to match(/unknown entities/)
    end

    it 'accepts nil entity_scope (all entities)' do
      matrix.entity_scope = nil
      expect(matrix).to be_valid
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

    it 'enforces name uniqueness among active matrices per account' do
      create(:caf_approval_matrix, account: account, name: 'Unique Matrix', active: true)
      dup = build(:caf_approval_matrix, account: account, name: 'Unique Matrix', active: true)
      expect(dup).not_to be_valid
    end

    it 'allows duplicate name on inactive matrices' do
      create(:caf_approval_matrix, account: account, name: 'Old Matrix', active: false)
      m = build(:caf_approval_matrix, account: account, name: 'Old Matrix', active: true)
      expect(m).to be_valid
    end
  end

  # ── .for (legacy) ────────────────────────────────────────────────────────────

  describe '.for' do
    before do
      matrix.document_type = 'nda'
      matrix.save!
    end

    it 'finds an active matrix by account and document_type' do
      expect(described_class.for(account, 'nda')).to eq(matrix)
    end

    it 'returns nil for an inactive matrix' do
      matrix.update!(active: false)
      expect(described_class.for(account, 'nda')).to be_nil
    end
  end

  # ── .resolve_for ─────────────────────────────────────────────────────────────

  describe '.resolve_for' do
    let!(:generic) do
      create(:caf_approval_matrix, account: account, name: 'Generic NDA',
             agreement_types: ['nda'], entity_scope: nil, value_threshold: nil)
    end

    let!(:entity_scoped) do
      create(:caf_approval_matrix, account: account, name: 'ITI NDA',
             agreement_types: ['nda'], entity_scope: ['iti'], value_threshold: nil)
    end

    let!(:threshold_matrix) do
      create(:caf_approval_matrix, account: account, name: 'NDA R5m+',
             agreement_types: ['nda'], entity_scope: nil, value_threshold: 5_000_000)
    end

    let!(:most_specific) do
      create(:caf_approval_matrix, account: account, name: 'ITI NDA R5m+',
             agreement_types: ['nda'], entity_scope: ['iti'], value_threshold: 5_000_000)
    end

    it 'returns the generic matrix when no entity or value given' do
      expect(described_class.resolve_for(account, agreement_type: 'nda')).to eq(generic)
    end

    it 'returns nil when no matrix covers the agreement type' do
      expect(described_class.resolve_for(account, agreement_type: 'employment')).to be_nil
    end

    it 'prefers entity-scoped matrix over generic' do
      result = described_class.resolve_for(account, agreement_type: 'nda', entity: 'iti')
      expect(result).to eq(entity_scoped)
    end

    it 'falls back to generic when entity does not match any scope' do
      result = described_class.resolve_for(account, agreement_type: 'nda', entity: 'comit')
      expect(result).to eq(generic)
    end

    it 'prefers threshold matrix when value meets threshold' do
      result = described_class.resolve_for(account, agreement_type: 'nda', value: 5_000_000)
      expect(result).to eq(threshold_matrix)
    end

    it 'falls back to generic when value is below threshold' do
      result = described_class.resolve_for(account, agreement_type: 'nda', value: 4_999_999)
      expect(result).to eq(generic)
    end

    it 'returns the most-specific matrix when entity + value both match' do
      result = described_class.resolve_for(
        account, agreement_type: 'nda', entity: 'iti', value: 10_000_000
      )
      expect(result).to eq(most_specific)
    end

    it 'ignores inactive matrices' do
      generic.update!(active: false)
      entity_scoped.update!(active: false)
      threshold_matrix.update!(active: false)
      most_specific.update!(active: false)
      expect(described_class.resolve_for(account, agreement_type: 'nda')).to be_nil
    end
  end

  # ── #deactivate! ─────────────────────────────────────────────────────────────

  describe '#deactivate!' do
    let!(:m) { create(:caf_approval_matrix, account: account, active: true) }

    it 'sets active to false' do
      m.deactivate!
      expect(m.reload.active).to be(false)
    end

    it 'logs a MATRIX_DEACTIVATED audit event' do
      expect { m.deactivate!(actor: user) }
        .to change { MatrixAuditEvent.where(event_type: 'MATRIX_DEACTIVATED').count }.by(1)
    end

    it 'returns false when already inactive' do
      m.update!(active: false)
      expect(m.deactivate!).to be(false)
    end
  end

  # ── #log_audit_event ─────────────────────────────────────────────────────────

  describe '#log_audit_event' do
    let!(:m) { create(:caf_approval_matrix, account: account) }

    it 'creates a MatrixAuditEvent' do
      expect { m.log_audit_event(CafApprovalMatrix::EVENT_CREATED, actor: user) }
        .to change(MatrixAuditEvent, :count).by(1)
    end

    it 'persists extra data in the jsonb data column' do
      m.log_audit_event(CafApprovalMatrix::EVENT_UPDATED, actor: user, extra: { note: 'QA pass' })
      expect(MatrixAuditEvent.last.data['note']).to eq('QA pass')
    end
  end

  # ── #build_stages_for ─────────────────────────────────────────────────────────

  describe '#build_stages_for' do
    let(:template)   { create(:template, author: user, account: account) }
    let(:submission) { create(:submission, template: template, created_by_user: user) }
    let!(:m)         { create(:caf_approval_matrix, account: account, stages_config: valid_stages_config) }

    it 'returns the correct number of stage objects' do
      expect(m.build_stages_for(submission).length).to eq(valid_stages_config.length)
    end

    it 'marks position 0 as active and subsequent as pending' do
      stages = m.build_stages_for(submission)
      expect(stages.first.status).to eq('active')
      expect(stages[1..].map(&:status)).to all(eq('pending'))
    end

    it 'sets strip_internal_on_complete from config' do
      stages = m.build_stages_for(submission)
      expect(stages.first.strip_internal_on_complete).to be(true)
      expect(stages.last.strip_internal_on_complete).to be(false)
    end

    it 'sets positions incrementally' do
      stages = m.build_stages_for(submission)
      expect(stages.map(&:position)).to eq([0, 1])
    end
  end
end
