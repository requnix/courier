require "socket"
require "logger"
require "habitat"
require "./session"
require "../store/memory"

class Courier::SMTP::Server
  getter log : Logger

  Habitat.create do
    setting port : Int32 = 25
    setting log : Logger = Logger.new(STDOUT, Logger::INFO)
    setting store : Courier::Store::Base = Courier::Store::Memory.new
  end

  def initialize
    @log = settings.log
    @server = TCPServer.new(settings.port)
  end

  def run
    log.info "#{self.class} running on port #{settings.port}"
    # Spawn fibers so connections are processed concurrently
    spawn do
      loop do
        spawn handle_session(@server.accept)
      end
    end
  end

  def handle_session(client : TCPSocket)
    session = Courier::SMTP::Session.new(client, settings.store)

    client_addr = client.remote_address
    connection_id = client.object_id
    log.info "#{self.class} connection #{connection_id} from #{client_addr} accepted"
    session.greet

    # Keep processing commands until somebody closes the connection
    while true
      break if client.closed?

      input = client.gets(false)
      next if input.nil?

      # The first word of a line should contain the command
      input = input.to_s
      command = input.split(' ', 2).first.upcase.strip
      log.debug "#{self.class} connection #{connection_id} < #{input.strip}"
      session.process_command(command, input)
    end
    log.info "#{self.class} connection #{connection_id} from #{client_addr} closed"
  rescue ex
    log.error "#{self.class} #{connection_id} ! #{ex}"
    client.close
  end
end
