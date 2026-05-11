# frozen_string_literal: true

# Join table: links a Submitter to a CafStage with an explicit role and position.
# Position controls notification order for ordered-routing stages.
# == Schema Information
#
# Table name: caf_stage_submitters
#
#  id           :bigint           not null, primary key
#  position     :integer          default(0), not null
#  role         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  caf_stage_id :bigint           not null
#  submitter_id :bigint           not null
#
# Indexes
#
#  index_caf_stage_submitters_on_caf_stage_id                   (caf_stage_id)
#  index_caf_stage_submitters_on_caf_stage_id_and_position      (caf_stage_id,position)
#  index_caf_stage_submitters_on_caf_stage_id_and_submitter_id  (caf_stage_id,submitter_id) UNIQUE
#  index_caf_stage_submitters_on_submitter_id                   (submitter_id)
#
# Foreign Keys
#
#  fk_rails_...  (caf_stage_id => caf_stages.id)
#  fk_rails_...  (submitter_id => submitters.id)
#
class CafStageSubmitter < ApplicationRecord
  belongs_to :caf_stage
  belongs_to :submitter

  validates :role, presence: true
  validates :position, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :submitter_id, uniqueness: { scope: :caf_stage_id }

  scope :ordered, -> { order(position: :asc) }
end
