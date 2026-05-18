# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Agreements', type: :request do
  let(:account) { create(:account) }
  let(:user)    { create(:user, account: account) }

  before { sign_in user }

  # ── Bug 2: send_agreement rejects blank counterparty_email ──────────────────

  describe 'POST /agreements/:id/send_agreement' do
    context 'when counterparty_email is blank' do
      let(:workflow) do
        create(:caf_workflow,
               account:            account,
               created_by_user:    user,
               agreement_type:     'nda',
               counterparty_email: '',
               status:             'draft')
      end

      it 'redirects back to review with an error and does not call CafSubmissionCreator' do
        expect(CafSubmissionCreator).not_to receive(:new)

        post send_agreement_agreement_path(workflow)

        expect(response).to redirect_to(review_agreement_path(workflow))
        expect(flash[:alert]).to match(/email is required/i)
      end
    end

    context 'when agreement is already submitted' do
      let(:workflow) do
        create(:caf_workflow,
               account:            account,
               created_by_user:    user,
               agreement_type:     'nda',
               counterparty_email: 'cp@example.com',
               status:             'pending_ig')
      end

      it 'redirects to show page with an alert' do
        post send_agreement_agreement_path(workflow)

        expect(response).to redirect_to(agreement_path(workflow))
        expect(flash[:alert]).to match(/already been submitted/i)
      end
    end
  end

  # ── Bug 6: caf_preview guards against blank entity ──────────────────────────

  describe 'GET /agreements/:id/caf_preview' do
    context 'when entity is blank' do
      let(:workflow) do
        build(:caf_workflow, account: account, created_by_user: user, entity: 'iti')
          .tap { |w| w.save(validate: false) }
          .tap { |w| w.update_column(:entity, '') }
      end

      it 'redirects to the agreement show page with an alert' do
        get caf_preview_agreement_path(workflow)

        expect(response).to redirect_to(agreement_path(workflow))
        expect(flash[:alert]).to match(/entity not selected/i)
      end
    end
  end
end
