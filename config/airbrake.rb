require "mail"
require "./lib/internal_alert.rb"

Airbrake.configure do |config|
  config.secure = false
  config.async do |notice|
    body = ""

    if notice.url
      body << "Params: #{notice.parameters.inspect}\r\n"
      body << "Session: #{notice.session_data.inspect}\r\n"
      body << "Env: #{notice.cgi_data.inspect}\r\n"
      body << "URL: #{notice.url}\r\n" if notice.url
      body << "Component: #{notice.controller}\r\n" if notice.controller
      body << "Action: #{notice.action}\r\n" if notice.action
      body << "\r\n"
    end

    body << "#{notice.error_message}\r\n\r\n"
    body << "#{notice.exception.backtrace.join("\r\n")}" if notice.exception.backtrace

    InternalAlert.deliver(notice.exception.class, "Error #{notice.exception.to_s}", body.strip)
  end
end