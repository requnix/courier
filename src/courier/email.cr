require "./address"

# Represents an email message
class Courier::Email
  # A digest used to identify the message
  #
  # This is populated once the DATA command completes
  property digest : String?
  property recipients : Hash(String, Array(Address))

  def initialize(@recipients = {
                   "TO"    => [] of Address,
                   "CC"    => [] of Address,
                   "BCC"   => [] of Address,
                   "REPLY" => [] of Address,
                 })
  end
end
