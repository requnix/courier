require "./base"

# Store that persists `Courier::Email`s to volatile memory
class Courier::Store::Memory < Courier::Store::Base
  def initialize
    @collection = [] of Courier::Email
  end
end
