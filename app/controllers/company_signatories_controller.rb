# frozen_string_literal: true

# IGSIGN — Admin management of memorised counterparty signatories.
# Allows toggling active status and editing role_title / authority_basis.
class CompanySignatoriesController < ApplicationController
  skip_authorization_check
  before_action :authenticate_user!
  before_action :set_signatory

  def update
    if @signatory.update(signatory_params)
      redirect_to company_path(@signatory.company),
                  notice: "#{@signatory.name} updated."
    else
      redirect_to company_path(@signatory.company),
                  alert: "Could not update: #{@signatory.errors.full_messages.to_sentence}"
    end
  end

  private

  def set_signatory
    # Scope to current account's companies to prevent cross-account access.
    company = current_account.companies
                             .joins(:company_signatories)
                             .find_by(company_signatories: { id: params[:id] })

    @signatory = company&.company_signatories&.find_by(id: params[:id])
    redirect_to companies_path, alert: 'Signatory not found.' unless @signatory
  end

  def signatory_params
    params.require(:company_signatory).permit(:active, :role_title, :authority_basis)
  end
end
