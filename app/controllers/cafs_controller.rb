# frozen_string_literal: true
# IGSIGN — CAF Workflow Controller
class CafsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_caf, only: %i[show edit update destroy]

  def index
    @cafs = current_account.caf_workflows.recent
                           .includes(:created_by_user, :caf_submission, :contract_submission)
    @stats = {
      total:    @cafs.count,
      pending:  @cafs.pending.count,
      complete: @cafs.complete.count,
    }
  end

  def show; end

  def new
    @caf = CafWorkflow.new
    @caf.requestor_name  = current_user.name
    @caf.requestor_email = current_user.email
    @caf.account         = current_account
  end

  def create
    @caf = CafWorkflow.new(caf_params)
    @caf.account            = current_account
    @caf.created_by_user    = current_user
    @caf.status             = 'draft'

    # Auto-assign signatories from entity + type logic
    @caf.auto_assign_signatories!

    # Override BU Head placeholder if provided
    if params[:caf_workflow][:bu_head_name].present?
      sigs = @caf.signatories.map do |s|
        if s['placeholder'] == true || s['key'] == 'bu_head'
          s.merge(
            'name'        => params[:caf_workflow][:bu_head_name],
            'email'       => params[:caf_workflow][:bu_head_email],
            'placeholder' => false
          )
        else
          s
        end
      end
      @caf.signatories = sigs
    end

    # Override any additional custom signatories passed from the form
    if params[:caf_workflow][:custom_signatories].present?
      begin
        custom = JSON.parse(params[:caf_workflow][:custom_signatories])
        @caf.signatories = custom if custom.is_a?(Array)
      rescue JSON::ParserError
        nil
      end
    end

    if @caf.save
      redirect_to caf_path(@caf), notice: 'CAF created. Review signatories and submit for approval.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @caf.update(caf_params)
      redirect_to caf_path(@caf), notice: 'CAF updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @caf.update!(status: 'cancelled')
    redirect_to cafs_path, notice: 'CAF cancelled.'
  end

  # POST /cafs/:id/submit — Finalise draft and create the DocuSeal submission
  def submit
    @caf = current_account.caf_workflows.find(params[:id])

    if @caf.draft?
      result = CafSubmissionCreator.new(@caf, current_user).call
      if result[:success]
        @caf.update!(status: 'pending_ig', caf_submission: result[:submission])
        redirect_to caf_path(@caf), notice: 'CAF submitted for internal approval. Signatories have been notified.'
      else
        redirect_to caf_path(@caf), alert: "Failed to create submission: #{result[:error]}"
      end
    else
      redirect_to caf_path(@caf), alert: 'Only draft CAFs can be submitted.'
    end
  end

  # GET /cafs/signatories_for — AJAX: return signatories for entity + type
  def signatories_for
    entity   = params[:entity]
    caf_type = params[:caf_type]
    chain    = IgSignatories.chain_for(caf_type, entity)
    render json: chain
  end

  private

  def set_caf
    @caf = current_account.caf_workflows.find(params[:id])
  end

  def caf_params
    params.require(:caf_workflow).permit(
      :entity, :caf_type, :requestor_name, :requestor_email,
      :contracting_party, :ignition_company,
      :counterparty_name, :counterparty_email,
      :high_level_summary, :mandate_description,
      :contract_document
    )
  end
end
