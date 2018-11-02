# Represents an interactive session with a client
class Courier::POP::Session
  enum State
    Authorization # https://tools.ietf.org/html/rfc1939#section-4
    Transaction   # https://tools.ietf.org/html/rfc1939#section-5
    Update        # https://tools.ietf.org/html/rfc1939#section-6
  end

  getter log : Logger

  # Creates a new session in the AUTHORIZATION state and greets
  def initialize(@client : TCPSocket, @store : Courier::Store::Base)
    # Use a shared log for this class
    @log = Server.settings.log
    # Put the session in the AUTHORIZATION state
    @state = State::Authorization
    # Record the last interaction for the inactivity timer
    @last_action = Time.now
    # Store an array of messages marked for deletion during UPDATE
    @pending_deletion = [] of String
    # Respond with any positive response
    respond true, "Courier POP3 Server ready"
  end

  # Process command limits actions by current state
  def process_command(command : String, full_data : String)
    # Update last interaction time to refresh the timeout
    @last_action = Time.now

    if @state.authorization?
      case command
      when "CAPA" then capa
      when "USER" then user(full_data)
      when "PASS" then pass(full_data)
      when "QUIT" then quit
      else
        respond false, "INVALID COMMAND"
      end
    elsif @state.transaction?
      case command
      when "STAT" then stat
      when "CAPA" then capa
      when "NOOP" then respond true, ""
      when "TOP"  then top(full_data)
      when "LIST" then list(message_number(full_data))
      when "UIDL" then uidl(message_number(full_data))
      when "RETR" then retr(message_number(full_data))
      when "DELE" then dele(message_number(full_data))
      when "RSET" then rset
      when "QUIT" then quit
      else
        respond false, "INVALID COMMAND"
      end
    else # @state.update?
      respond false, "NO COMMANDS ACCEPTED DURING UPDATE"
    end
  end

  # Show the client what we can do
  def capa
    respond true, "Here's what I can do:\r\nUSER\r\nIMPLEMENTATION Courier POP3 Server\r\n."
  end

  # TODO: Process username
  def user(full_data)
    respond true, "AWAITING PASSWORD"
  end

  # TODO: Authenticate client
  def pass(full_data)
    @state = State::Transaction
    respond true, "LOGGED IN"
  end

  # Shows total number of messages and size of all messages
  #
  # See: https://tools.ietf.org/html/rfc1939#page-6
  def stat
    respond true, "#{@store.count} #{@store.total_size}"
  end

  # Show list of messages
  #
  # When a message ID is specified only list the size of that message
  #
  # See: https://tools.ietf.org/html/rfc1939#page-6
  def list(requested)
    if requested.is_a? Int
      respond true, "#{requested} #{@store.retrieve(requested).size}"
    elsif requested == :all
      response = "#{@store.count} messages (#{@store.total_size} octets)\r\n"
      @store.all.each_with_index do |email, index|
        next if @pending_deletion.includes? email.digest
        response += "#{index} #{email.size}\r\n"
      end
      respond true, "#{response}."
    else
      respond false, "INVALID MESSAGE NUMBER"
    end
  end

  # Retreive a message by message number
  #
  # See: https://tools.ietf.org/html/rfc1939#page-8
  def retr(requested)
    if requested.is_a? Int
      email = @store.retrieve requested
      respond true, "#{email.size} octets\r\n" + email.serialize + "\r\n."
    else
      respond false, "INVALID MESSAGE NUMBER"
    end
  end

  # Mark a message for deletion
  #
  # It will be deleted once the session reaches the UPDATE state. If the
  # message has already been deleted, it returns a negative response.
  #
  # See: https://tools.ietf.org/html/rfc1939#page-8
  def dele(requested)
    if requested.is_a? Int
      digest = @store.retrieve(requested).digest
      if @pending_deletion.includes? digest
        respond false, "MESSAGE #{requested} ALREADY DELETED"
      else
        @pending_deletion << @store.retrieve(requested).digest
        respond true, "MESSAGE #{requested} DELETED"
      end
    else
      respond false, "NO SUCH MESSAGE"
    end
  end

  # Reset all changes done in this transaction
  #
  # See: https://tools.ietf.org/html/rfc1939#page-9
  def rset
    @pending_deletion.clear
    respond true, "#{@store.count} messages (#{@store.total_size} octets)\r\n"
  end

  # Shows list of message uid
  #
  # When a message id is specified only list
  # the uid of that message
  def uidl(requested)
    if requested.is_a? Int
      email = @store.retrieve(requested)
      respond(true, "#{requested} #{email.digest}")
    elsif requested == :invalid
      respond(false, "Invalid message number")
    elsif requested == :all
      response = "Unique identifier listing follows:\r\n"
      @store.all.each_with_index do |mail, index|
        response += "#{index} #{mail.digest}\r\n"
      end
      respond(true, response)
    else
      respond(false, "Invalid message number")
    end
  end

  # Display headers of message
  def top(full_data)
    full_data = full_data.split(/TOP\s(\d*)/i)
    message_index = full_data[1].to_i
    number_of_lines = full_data[2].to_i

    emails = @store.all
    if emails.size >= message_index && message_index > 0
      headers = ""
      line_number = -2 # offset to add subject and spacer lines
      emails[message_index - 1].body.split(/\r\n/).each do |line|
        line_number += 1 if line.gsub(/\r\n/, "") == "" || line_number > -2
        headers += "#{line}\r\n" if line_number < number_of_lines
      end
      respond(true, "Message headers follow:\r\n" + headers + "\r\n.")
    else
      respond(false, "Invalid message number")
    end
  end

  # Commit changes if in the transaction state, otherwise close the connection
  #
  # See: https://tools.ietf.org/html/rfc1939#page-9
  def quit
    if @state.transaction?
      @pending_deletion.each do |identifier|
        @store.delete identifier
      end
    end
    respond true, "Thanks for stopping by!"
    @client.close
  end

  # protected

  # Returns message number parsed from full_data:
  #
  # * No message number => :all
  # * Message does not exists => :invalid
  # * valid message number => some fixnum
  def message_number(full_data)
    if /\w*\s*\d/ =~ full_data
      requested = full_data.gsub(/\D/, "").to_i
      if @store.count >= requested && requested > 0
        return requested
      else
        return :invalid
      end
    else
      return :all
    end
  end

  # Respond to client with a POP3 prefix (+OK or -ERR)
  def respond(status : Bool, message : String)
    log.debug "#{@client.object_id} > #{status ? "+OK" : "-ERR"} #{message}"
    @client.write "#{status ? "+OK" : "-ERR"} #{message}\r\n".to_slice
  rescue ex
    log.error "#{@client.object_id} ! #{ex}"
    @client.close
  end
end
