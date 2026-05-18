# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CafWorkflow, '#next_draft_step', type: :model do
  subject(:workflow) { build(:caf_workflow, agreement_type: agreement_type, template_id: template_id) }

  let(:template_id) { nil }

  context 'NDA agreement' do
    let(:agreement_type) { 'nda' }

    it 'returns :review regardless of template state' do
      expect(workflow.next_draft_step).to eq(:review)
    end

    it 'returns :review even when template_id is nil' do
      workflow.template_id = nil
      expect(workflow.next_draft_step).to eq(:review)
    end
  end

  context 'non-NDA agreement with no template' do
    let(:agreement_type) { 'msa' }
    let(:template_id) { nil }

    it 'returns :upload' do
      expect(workflow.next_draft_step).to eq(:upload)
    end
  end

  context 'non-NDA agreement with template but no fields' do
    let(:agreement_type) { 'msa' }
    let(:template) { instance_double(Template, fields: []) }

    before do
      workflow.template_id = 42
      allow(workflow).to receive(:template).and_return(template)
    end

    it 'returns :position' do
      expect(workflow.next_draft_step).to eq(:position)
    end
  end

  context 'non-NDA agreement with template and fields placed' do
    let(:agreement_type) { 'msa' }
    let(:template) { instance_double(Template, fields: [{ 'type' => 'signature' }]) }

    before do
      workflow.template_id = 42
      allow(workflow).to receive(:template).and_return(template)
    end

    it 'returns :review' do
      expect(workflow.next_draft_step).to eq(:review)
    end
  end

  context 'vendor agreement type' do
    let(:agreement_type) { 'vendor' }

    it 'returns :upload when no template' do
      expect(workflow.next_draft_step).to eq(:upload)
    end
  end
end
