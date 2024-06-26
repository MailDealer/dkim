
require 'dkim/signed_mail'
require 'dkim/options'
require 'dkim/interceptor'

module Dkim
  DefaultHeaders = %w{ Date From To Message-ID Subject MIME-Version Content-Type Content-Transfer-Encoding List-Unsubscribe List-Id Reply-To Cc
                       Date From To Message-ID Subject MIME-Version Content-Type Content-Transfer-Encoding List-Unsubscribe List-Id Reply-To Cc }

  class << self
    include Dkim::Options

    def sign message, options={}
      SignedMail.new(message, options).to_s
    end
  end
end

Dkim::signable_headers        = Dkim::DefaultHeaders.dup
Dkim::domain                  = nil
Dkim::identity                = nil
Dkim::selector                = nil
Dkim::signing_algorithm       = 'rsa-sha256'
Dkim::private_key             = nil
Dkim::header_canonicalization = 'relaxed'
Dkim::body_canonicalization   = 'relaxed'

