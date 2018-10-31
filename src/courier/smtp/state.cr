# Encapsulates the state of an SMTP session in progress
class Courier::SMTP::State
  property in_progress
  getter pending_mails

  def initialize
    @pending_mails = [] of Courier::Email
    @in_progress = Courier::Email.new
  end
end
