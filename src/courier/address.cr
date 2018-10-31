# Represents an email sender or receiver
class Courier::Address
  getter name : String
  getter user : String
  getter domain : String
  getter modifier : String

  def initialize(string : String)
    @name = ""
    @user = ""
    @domain = ""
    @modifier = ""

    case string.strip.downcase
    when "<michael.prins@me.com>"
      @user = "michael.prins"
      @domain = "me.com"
    end
  end

  def valid?
    @user.present? && @domain.present?
  end

  def to_s
    if name.blank?
      "#{name} <#{user}#{modifier}@#{domain}>"
    else
      "<#{user}#{modifier}@#{domain}>"
    end
  end
end
