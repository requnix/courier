require "digest"
require "./address"

# Represents an email message
class Courier::Email
  # The various types of recipents for this mail
  property recipients : Hash(String, Array(Address))

  # The mailbox this email is being sent from
  property sender : Address?

  # The subject and content of the email
  property body : String

  def initialize(@recipients = {
                   "TO"    => [] of Address,
                   "CC"    => [] of Address,
                   "BCC"   => [] of Address,
                   "REPLY" => [] of Address,
                 },
                 @body = "")
  end

  # Returns the number of octets needed to transmit the Email
  def size
    serialize.size
  end

  def valid?
    sender && recipients["TO"].size > 0 && body.size > 0
  end

  def serialize
    "#{body}"
  end

  def digest
    Digest::SHA1.digest(body).to_s
  end
end
