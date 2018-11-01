require "option_parser"
require "./courier/store/memory"
require "./courier/smtp/server"
require "./courier/pop/server"

OptionParser.parse! do |parser|
  parser.banner = "Usage: courier [options]"

  parser.on("-h", "--help", "Display this screen") do
    puts parser
    exit
  end

  parser.on("-p PORT", "--pop3 PORT", "Specify POP3 port to use") do |port|
    pop3_port = port.to_i
  end

  parser.on("-s PORT", "--smtp PORT", "Specify SMTP port to use") do |port|
    smtp_port = port.to_i
  end

  parser.on("-v", "--verbose", "Output more information") do
    verbose = true
  end
end

# Shared
log = Logger.new(STDOUT, Logger::DEBUG)
store = Courier::Store::Memory.new

# SMTP Server
Courier::SMTP::Server.settings.log = log
Courier::SMTP::Server.settings.store = store
Courier::SMTP::Server.new.run

# POP3 Server
Courier::POP::Server.settings.log = log
Courier::POP::Server.settings.store = store
Courier::POP::Server.new.run

sleep
