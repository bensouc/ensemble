# FactoryBot.define do
#   factory(:subscription) do
#     cancel_at_period_end false
#     current_period_end {"2024-08-31"}
#     current_period_start {"2023-09-01"}
#     plan_id {"group_annualy"}
#     quantity nil
#     school {School.all.sample}
#     start_date {"2023-09-01"}
#     status {"active"}
#     stripe_subscription_id {""}
#     trial_end {"2023-09-25"}
#   end
# end
