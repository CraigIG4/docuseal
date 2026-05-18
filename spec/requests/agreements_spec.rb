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

  # ── Prompt 2: remind endpoint ────────────────────────────────────────────────

  describe 'POST /agreements/:id/remind' do
    context 'when no submission exists' do
      let(:workflow) do
        create(:caf_workflow, account: account, created_by_user: user,
                              agreement_type: 'nda', status: 'draft')
      end

      it 'redirects with an alert' do
        post remind_agreement_path(workflow)

        expect(response).to redirect_to(agreement_path(workflow))
        expect(flash[:alert]).to match(/not been submitted/i)
      end
    end

    context 'when the workflow is active with pending submitters' do
      let(:submission) { create(:submission, account: account) }
      let(:workflow) do
        create(:caf_workflow, account: account, created_by_user: user,
                              agreement_type: 'msa', status: 'pending_ig',
                              caf_submission: submission)
      end
      let(:stage)      { create(:caf_stage, submission: submission, status: 'active') }
      let(:submitter)  { create(:submitter, submission: submission) }
      let!(:css) do
        create(:caf_stage_submitter, caf_stage: stage, submitter: submitter,
                                     invited_at: 3.days.ago)
      end

      it 'queues a reminder and redirects with a notice' do
        allow(ReminderMailer).to receive_message_chain(:signing_reminder, :deliver_later)

        post remind_agreement_path(workflow)

        expect(response).to redirect_to(agreement_path(workflow))
        expect(flash[:notice]).to match(/reminder/i)
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
