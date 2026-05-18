# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReminderCheckJob, type: :job do
  let(:account)    { create(:account) }
  let(:submission) { create(:submission, account: account) }
  let(:stage)      { create(:caf_stage, submission: submission, status: 'active') }
  let(:submitter)  { create(:submitter, submission: submission, sent_at: 3.days.ago) }

  # Helper: build an unsign CSS at a given overdue tier
  def make_css(trait)
    create(:caf_stage_submitter, trait, caf_stage: stage, submitter: submitter)
  end

  describe '#perform' do
    context 'day-2 reminder (reminder_count == 0, invited >= 2 days ago)' do
      it 'sends a signing_reminder and increments reminder_count' do
        css = make_css(:overdue_day2)
        mailer_dbl = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
        allow(ReminderMailer).to receive(:signing_reminder).with(css, 2).and_return(mailer_dbl)

        described_class.new.perform

        expect(ReminderMailer).to have_received(:signing_reminder).with(css, 2)
        expect(css.reload.reminder_count).to eq(1)
        expect(css.reload.reminder_sent_at).to be_within(5.seconds).of(Time.current)
      end
    end

    context 'day-5 reminder (reminder_count == 1, invited >= 5 days ago)' do
      it 'sends a signing_reminder and increments reminder_count' do
        css = make_css(:overdue_day5)
        mailer_dbl = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
        allow(ReminderMailer).to receive(:signing_reminder).with(css, 5).and_return(mailer_dbl)

        described_class.new.perform

        expect(ReminderMailer).to have_received(:signing_reminder).with(css, 5)
        expect(css.reload.reminder_count).to eq(2)
      end
    end

    context 'day-9 reminder (reminder_count == 2, invited >= 9 days ago)' do
      it 'sends a signing_reminder and increments reminder_count' do
        css = make_css(:overdue_day9)
        mailer_dbl = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
        allow(ReminderMailer).to receive(:signing_reminder).with(css, 9).and_return(mailer_dbl)

        described_class.new.perform

        expect(ReminderMailer).to have_received(:signing_reminder).with(css, 9)
        expect(css.reload.reminder_count).to eq(3)
      end
    end

    context 'day-14 escalation (invited >= 14 days ago, escalated_at nil)' do
      it 'sends an escalation_notice and stamps escalated_at' do
        css = make_css(:overdue_day14)
        mailer_dbl = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
        allow(ReminderMailer).to receive(:escalation_notice).with(css).and_return(mailer_dbl)

        described_class.new.perform

        expect(ReminderMailer).to have_received(:escalation_notice).with(css)
        expect(css.reload.escalated_at).not_to be_nil
      end
    end

    context 'already escalated signatory' do
      it 'does not re-send escalation' do
        css = make_css(:overdue_day14)
        css.update_columns(escalated_at: 1.day.ago)
        allow(ReminderMailer).to receive(:escalation_notice)

        described_class.new.perform

        expect(ReminderMailer).not_to have_received(:escalation_notice)
      end
    end

    context 'submitter already completed' do
      it 'skips reminder for completed submitters' do
        css = make_css(:overdue_day2)
        css.submitter.update_columns(completed_at: 1.hour.ago)
        allow(ReminderMailer).to receive(:signing_reminder)

        described_class.new.perform

        expect(ReminderMailer).not_to have_received(:signing_reminder)
      end
    end

    context 'stage not active' do
      it 'skips reminder for submitters in completed stages' do
        stage.update_columns(status: 'complete')
        css = make_css(:overdue_day2)
        allow(ReminderMailer).to receive(:signing_reminder)

        described_class.new.perform

        expect(ReminderMailer).not_to have_received(:signing_reminder)
      end
    end

    context 'invited_at not yet set' do
      it 'skips reminder when invite has not been stamped' do
        css = create(:caf_stage_submitter, caf_stage: stage, submitter: submitter,
                                           invited_at: nil, reminder_count: 0)
        allow(ReminderMailer).to receive(:signing_reminder)

        described_class.new.perform

        expect(ReminderMailer).not_to have_received(:signing_reminder)
      end
    end
  end
end
