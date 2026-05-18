# frozen_string_literal: true

# IGSIGN — Mailer for the signing reminder and escalation ladder.
#
# signing_reminder: nudges the signatory directly (day 2 / 5 / 9).
# escalation_notice: alerts the workflow requestor when a signatory has been
#   outstanding for ESCALATION_THRESHOLD_DAYS (day 14).
class ReminderMailer < ApplicationMailer
  default from: -> { GlobalConfig.dig(:app, :from_email) || 'igsign@ignitiongroup.co.za' }

  # Sends a reminder to the submitter.
  #
  # @param css [CafStageSubmitter] the stage submitter record
  # @param days_outstanding [Integer] number of days since the invite was sent
  def signing_reminder(css, days_outstanding)
    @css              = css
    @submitter        = css.submitter
    @days_outstanding = days_outstanding
    @caf              = css.caf_workflow
    @signing_url      = submitter_signing_url(@submitter)

    assign_message_metadata('signing_reminder', @submitter)

    mail(
      to:      "\"#{@submitter.name}\" <#{@submitter.email}>",
      subject: reminder_subject
    )
  end

  # Sends an escalation notice to the workflow requestor.
  #
  # @param css [CafStageSubmitter] the stage submitter record
  def escalation_notice(css)
    @css       = css
    @submitter = css.submitter
    @caf       = css.caf_workflow

    return if @caf.nil? || @caf.requestor_email.blank?

    @days_outstanding = ReminderCheckJob::ESCALATION_THRESHOLD_DAYS
    @signing_url      = submitter_signing_url(@submitter)
    @agreement_url    = agreement_url(@caf, host: default_url_options[:host])

    assign_message_metadata('escalation_notice', @submitter)

    mail(
      to:      "\"#{@caf.requestor_name}\" <#{@caf.requestor_email}>",
      subject: "ACTION REQUIRED — Signature outstanding: #{@submitter.name} — " \
               "#{@caf.contracting_party}"
    )
  end

  private

  def reminder_subject
    urgency = case @days_outstanding
              when 2 then 'Reminder'
              when 5 then 'Action Required'
              else        'Urgent: Signature Overdue'
              end
    "#{urgency} — Please sign: #{@caf&.contracting_party || 'IGSIGN Agreement'}"
  end

  def submitter_signing_url(submitter)
    host = default_url_options[:host]
    return '' if submitter.slug.blank?

    Rails.application.routes.url_helpers.submit_form_url(
      submitter.slug,
      host: host
    )
  end

  def agreement_url(caf, host:)
    Rails.application.routes.url_helpers.agreement_url(caf, host: host)
  end
end
