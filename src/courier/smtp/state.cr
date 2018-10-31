# Encapsulates the state of an SMTP session in progress
class Courier::SMTP::State
  property in_progress : Courier::Email
  getter pending_mails : Array(Courier::Email)
  getter sending_data

  def initialize
    @pending_mails = [] of Courier::Email
    @in_progress = Courier::Email.new
    @sending_data = false
  end

  def start_data!
    @sending_data = true
  end

  def reset!
    @in_progress = Courier::Email.new
    @sending_data = false
  end

  def finalize_mail!
    if @in_progress.valid?
      @pending_mails << @in_progress
      @in_progress = Courier::Email.new
      @sending_data = false
      return true
    else
      return false
    end
  end
end
