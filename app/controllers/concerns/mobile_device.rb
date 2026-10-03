# frozen_string_literal: true

# Repère un téléphone ou une tablette au user agent, pour les vues qui ne
# s'affichent pas pareil sur petit écran.
#
# Reprend à l'identique la gem `mobile` 0.0.1 (abandonnée, et qui dépendait de
# `rails` sans borne) : même liste, tablettes comprises (« ipad »). Changer la
# liste changerait la mise en page servie à des enseignants.
module MobileDevice
  extend ActiveSupport::Concern

  USER_AGENTS = Regexp.new(
    "palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|" \
    "audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|" \
    "x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|" \
    "pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|" \
    "webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|" \
    "mobile"
  )

  included do
    helper_method :mobile_device?
  end

  def mobile_device?
    USER_AGENTS.match?(request.user_agent.to_s.downcase)
  end
end
