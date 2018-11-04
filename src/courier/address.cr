# Represents an email sender or receiver
class Courier::Address
  getter display_name : String
  getter local : String
  getter domain : String

  def initialize(string : String)
    @display_name = ""
    @local = ""
    @domain = ""

    if match = string.strip.match(/^<?(\w+\+?\w*)@(\w+.\w+)>?$/)
      @local = match[1].downcase
      @domain = match[2].downcase
    elsif match = string.strip.match(/^"(.*)" ?<?(\w+\+?\w*)@(\w+.\w+)>?$/)
      @display_name = match[1]
      @local = match[2].downcase
      @domain = match[3].downcase
    end
  end

  def valid?
    !@local.blank? && !@domain.blank?
  end

  def to_s
    if display_name.blank?
      "#{local}@#{domain}"
    else
      "\"#{display_name}\" <#{local}@#{domain}>"
    end
  end
end
