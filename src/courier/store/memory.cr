require "./base"

# Store that persists `Courier::Email`s to volatile memory
class Courier::Store::Memory < Courier::Store::Base
  def initialize
    @collection = {} of String => Courier::Email
  end

  # Number of messages available
  def count
    @collection.size
  end

  # Total size of all messages
  def total_size
    @collection.map(&.size).sum
  end

  # Retrieve all messages
  def all
    @collection.values
  end

  # Retrieve a message by message index (non-zero-based)
  def retrieve(index : Int)
    @collection.values[index - 1]
  end
  # Retrieve a message by unique identifier
  def retrieve(identifier : String)
    @collection[identifier]
  end

  # Remove the message with the given identifier from the store permanently
  def delete(identifier)
    @collection.delete identifier
  end

  # Persist the email so it can be retrieved later
  def persist(email)
    @collection[email.digest] = email
  end
end
