#!/usr/bin/env ruby

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") { $running = false; throw :interrupted }
logger = ActionMailer::Base.logger || ActiveRecord::Base.logger

host = ARGV.shift
port = ARGV.shift.to_i
logger.info "daemon #{__FILE__} started at #{RAILS_ENV} environment"
server = TCPServer.new(host, port)
while($running) do
  catch (:interrupted) {
    sock = server.accept
    Thread.start do
      begin
        mail = sock.read
        MailHandler.receive(mail) unless mail.empty?
      rescue
        bt = $!.backtrace.join("\n")
        logger.error "#{$!.message}:#{bt}"
      ensure
        sock.close unless sock.closed?
      end
    end
  }
end
logger.info "daemon #{__FILE__} stopped at #{RAILS_ENV} environment"
