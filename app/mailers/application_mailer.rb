class ApplicationMailer < ActionMailer::Base
  default from: "bensoucdev@gmail.com"
  layout "mailer"
  helper MailStylesHelper
end
