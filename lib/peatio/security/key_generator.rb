require 'fileutils'

module Peatio::Security
  class KeyGenerator

    attr_reader :public, :private

    def initialize
      OpenSSL::PKey::RSA.generate(2048).tap do |pkey|
        @public = pkey.public_key.to_pem
        @private = pkey.to_pem
      end
    end

    def save(folder)
      FileUtils.mkdir_p(folder) unless File.exists?(folder)

      write(File.join(folder, 'rsa-key'), @private)
      write(File.join(folder, 'rsa-key.pub'), @public)
    end

    def write(filename, text)
      File.open(filename, 'w') { |file| file.write(text) }
    end
  end
end
