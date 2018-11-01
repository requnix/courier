require "../email"

# Defines the API for persisting `Courier::Email`s
abstract class Courier::Store::Base
  # Number of messages available
  abstract def count : Int

  # Total size of all messages
  abstract def total_size : Int

  # Retrieve all messages
  abstract def all : Array(Courier::Email)

  # Retrieve a message by message index (non-zero-based)
  abstract def retrieve(index : Int) : Courier::Email
  # Retrieve a message by unique identifier
  abstract def retrieve(identifier : String) : Courier::Email

  # Remove the message with the given identifier from the store permanently
  abstract def delete(identifier : String)

  # Persist the email so it can be retrieved later
  abstract def persist(email : Courier::Email)
end
