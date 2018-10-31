require "../email"

# Defines the API for persisting `Courier::Email`s
abstract class Courier::Store::Base
  abstract def persist(email : Courier::Email)
end
