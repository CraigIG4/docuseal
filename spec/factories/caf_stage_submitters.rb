# frozen_string_literal: true

FactoryBot.define do
  factory :caf_stage_submitter do
    caf_stage
    submitter
    role     { 'CLO' }
    position { 0 }

    trait :with_invite do
      invited_at { 1.day.ago }
    end

    trait :overdue_day2 do
      invited_at     { 3.days.ago }
      reminder_count { 0 }
    end

    trait :overdue_day5 do
      invited_at     { 6.days.ago }
      reminder_count { 1 }
    end

    trait :overdue_day9 do
      invited_at     { 10.days.ago }
      reminder_count { 2 }
    end

    trait :overdue_day14 do
      invited_at     { 15.days.ago }
      reminder_count { 3 }
      escalated_at   { nil }
    end
  end
end
