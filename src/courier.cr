require "option_parser"
require "./courier/smtp/server"

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

smtp_server = Courier::SMTP::Server.new
smtp_server.run
sleep
