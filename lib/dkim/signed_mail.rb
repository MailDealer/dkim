require 'openssl'

require 'dkim/body'
require 'dkim/dkim_header'
require 'dkim/header'
require 'dkim/options'
require 'dkim/canonicalized_headers'

module Dkim
  class SignedMail
    include Options

    # A new instance of SignedMail
    #
    # @param [String,#to_s] message mail message to be signed
    # @param [Hash] options hash of options for signing. Defaults are taken from {Dkim}. See {Options} for details.
    def initialize(message)
      message = message.to_s.gsub(/\r?\n/, "\r\n")
      headers, body = message.split(/\r?\n\r?\n/, 2)
      @original_message = message
      @headers = Header.parse headers
      @body    = Body.new body
    end

    # @return [Array<String>] lowercased names of headers in the order they are signed
    def signed_headers
      @signed_headers ||= signable_headers
    end

    # @return [String] Signed headers of message in their canonical forms
    def canonical_header
      @canonical_header ||= CanonicalizedHeaders.new(@headers, signed_headers).to_s(header_canonicalization)
    end

    # @return [String] Body of message in its canonical form
    def canonical_body
      @canonical_body ||= @body.to_s(body_canonicalization)
    end

    def body_hash
      @body_hash ||= digest_alg.digest(canonical_body)
    end

    # @return [DkimHeader] Constructed signature for the mail message
    def dkim_header(options)
      @options = Dkim.options.merge(options)

      raise "A private key is required" unless private_key
      raise "A domain is required"      unless domain
      raise "A selector is required"    unless selector

      dkim_header = DkimHeader.new

      # Add basic DKIM info
      dkim_header['v'] = '1'
      dkim_header['a'] = signing_algorithm
      dkim_header['c'] = "#{header_canonicalization}/#{body_canonicalization}"
      dkim_header['d'] = domain
      dkim_header['i'] = identity if identity
      dkim_header['q'] = 'dns/txt'
      dkim_header['s'] = selector
      dkim_header['t'] = (time || Time.now).to_i
      dkim_header['x'] = expire.to_i if expire

      # Add body hash and blank signature
      dkim_header['bh']= body_hash
      dkim_header['h'] = signed_headers.join(':')
      dkim_header['b'] = ''

      # Calculate signature based on intermediate signature header
      headers_for_sign = canonical_header.dup
      headers_for_sign << dkim_header.to_s(header_canonicalization)
      dkim_header['b'] = private_key.sign(digest_alg, headers_for_sign)
      dkim_header
    end

    # @return [String] Message combined with calculated dkim header signature
    def to_s
      dkim_header.to_s + "\r\n" + @original_message
    end

    private
    def digest_alg
      case signing_algorithm
      when 'rsa-sha1'
        OpenSSL::Digest::SHA1.new
      when 'rsa-sha256'
        OpenSSL::Digest::SHA256.new
      else
        raise "Unknown digest algorithm: '#{signing_algorithm}'"
      end
    end
  end
end
