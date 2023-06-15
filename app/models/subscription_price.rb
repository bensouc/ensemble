require "ostruct"

class SubscriptionPrice
  MONTHLY_20 = OpenStruct.new({
    id: "price_1HXTMsB5y*****",
    name: "quarter-20",
    amount: 12,
    currency: "euros",
    interval: "quarter",
  })

  YEARLY_220 = OpenStruct.new({
    id: "price_1HXTMs*****",
    name: "yearly-220",
    amount: 40,
    currency: "usd",
    interval: "year",
  })

  def self.current_monthly
    MONTHLY_20
  end

  def self.current_yearly
    YEARLY_220
  end
end
