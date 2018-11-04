require "./spec_helper"
require "../src/courier/address"

# See https://tools.ietf.org/html/rfc5322#section-3.4
describe Courier::Address do
  describe "initialization" do
    it "parses only an address spec without angle brackets" do
      address = Courier::Address.new "mailbox@domain.org"
      address.local.should eq "mailbox"
      address.domain.should eq "domain.org"
    end

    it "parses only an address spec with angle brackets" do
      address = Courier::Address.new "<mailbox@domain.org>"
      address.local.should eq "mailbox"
      address.domain.should eq "domain.org"
    end

    it "parses a display name and address spec" do
      address = Courier::Address.new "\"Mailbox\" <mailbox@domain.org>"
      address.display_name.should eq "Mailbox"
      address.local.should eq "mailbox"
      address.domain.should eq "domain.org"
    end

    it "accepts a modifier in the local part" do
      address = Courier::Address.new "mailbox+spec@domain.org"
      address.local.should eq "mailbox+spec"
    end
  end

  describe "serialization" do
    context "with display name" do
      it "renders correctly" do
        address = Courier::Address.new("\"Display Name\" <mailbox@domain.org>")
        address.to_s.should eq "\"Display Name\" <mailbox@domain.org>"
      end
    end

    context "without display name" do
      it "renders as an address spec without brackets" do
        address = Courier::Address.new("mailbox@domain.org")
        address.to_s.should eq "mailbox@domain.org"
      end
    end
  end

  describe "validation" do
    it "identifies a valid address" do
      address = Courier::Address.new("mailbox@domain.org")
      address.valid?.should be_truthy
    end

    it "identifies an invalid address" do
      address = Courier::Address.new("erroneous")
      address.valid?.should be_falsey
    end
  end
end
