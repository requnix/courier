require "logger"
require "./state"

# A session with a client
class Courier::SMTP::Session
  # Standard SMTP response codes
  RESPONSES = {
    211 => "System status, or system help respond",
    214 => "Help message",
    220 => "Post Office Service ready",
    221 => "Post Office Service closing transmission channel",
    250 => "Requested mail action okay, completed",
    251 => "User not local; will forward to <forward-path>",
    354 => "Start mail input; end with <CRLF>.<CRLF>",
    421 => "Post Office Service not available,",
    450 => "Requested mail action not taken: mailbox unavailable",
    451 => "Requested action aborted: error in processing",
    452 => "Requested action not taken: insufficient system storage",
    500 => "Syntax error, command unrecognized",
    501 => "Syntax error in parameters or arguments",
    502 => "Command not implemented",
    503 => "Bad sequence of commands",
    504 => "Command parameter not implemented",
    550 => "Requested action not taken: mailbox unavailable",
    551 => "User not local; please try <forward-path>",
    552 => "Requested mail action aborted: exceeded storage allocation",
    553 => "Requested action not taken: mailbox name not allowed",
    554 => "Transaction failed",
  }

  getter log : Logger

  def initialize(@client : TCPSocket, @store : Courier::Store::Base)
    @log = Server.settings.log
    @state = State.new
  end

  def process_command(command : String, full_data : String)
    case command
    when "DATA"         then data
    when "HELO", "EHLO" then respond(250)
    when "NOOP"         then respond(250)
    when "MAIL"         then mail_from(full_data)
    when "QUIT"         then quit
    when "RCPT"         then recipient(full_data)
    when "RSET"         then rset
    else
      if @state.sending_data
        append_data(full_data)
      else
        respond(500)
      end
    end
  end

  # Send a greeting to client
  def greet
    respond(220)
  end

  # Close connection
  def quit
    # Persist emails in @state.pending_mails to a Courier::Store::Base
    @state.pending_mails.each { |mail| @store.persist(mail) }
    respond(221)
    @client.close
  end

  # Store sender address
  def mail_from(full_data)
    if /^MAIL FROM:/ =~ full_data.upcase
      @state.in_progress.sender = Courier::Address.new(
        full_data.gsub(/^MAIL FROM:\s*/i, "").gsub(/[\r\n]/, "")
      )
      respond(250)
    else
      respond(500)
    end
  end

  # Store recepient address
  def recipient(full_data)
    if /^RCPT TO:/ =~ full_data.upcase
      @state.in_progress.recipients["TO"] << Courier::Address.new(
        full_data.gsub(/^RCPT TO:\s*/i, "").gsub(/[\r\n]/, "")
      )
      respond(250)
    elsif /^RCPT CC:/ =~ full_data.upcase
      @state.in_progress.recipients["CC"] << Courier::Address.new(
        full_data.gsub(/^RCPT CC:\s*/i, "").gsub(/[\r\n]/, "")
      )
      respond(250)
    elsif /^RCPT BCC:/ =~ full_data.upcase
      @state.in_progress.recipients["CC"] << Courier::Address.new(
        full_data.gsub(/^RCPT BCC:\s*/i, "").gsub(/[\r\n]/, "")
      )
      respond(250)
    else
      respond(500)
    end
  end

  # Mark client sending data
  def data
    @state.start_data!
    respond(354)
  end

  # Reset current session
  def rset
    @state.reset!
    respond(250)
  end

  # Append data to incoming mail message
  #
  # full_data == "." indicates the end of the message
  def append_data(full_data : String)
    if full_data.gsub(/[\r\n]/, "") == "."
      log.info "Received mail from #{@state.in_progress.sender.to_s} to #{@state.in_progress.recipients["TO"][0].to_s}"
      if @state.finalize_mail!
        respond(250)
      else
        respond(554)
      end
    else
      @state.in_progress.body = @state.in_progress.body + full_data
    end
  end

  # Respond with a standard SMTP response code
  def respond(code : Int32)
    log.debug "#{@client.object_id} > #{code} #{RESPONSES[code]}"
    @client.write "#{code} #{RESPONSES[code]}\r\n".to_slice
  rescue ex
    log.error "#{@client.object_id} ! #{ex}"
    @client.close
  end
end
