module Peatio::Security
  class KeyGenerator

    # Function: 'keypair_gen' returns private and public key as an array of strings.
    # In array private key is the first and public - second one.
    def keypair_gen
      OpenSSL::PKey::RSA.generate(2048).yield_self do |p|
        { public:  Base64.urlsafe_encode64(p.public_key.to_pem), private: Base64.urlsafe_encode64(p.to_pem) }
          return p, p.public_key
      end
    end

    def output
      puts keypair_gen
    end

    def save
      Dir.mkdir('secrets') unless File.exists?('secrets')

      write('secrets/rsa-key', keypair_gen.first)
      write('secrets/rsa-key.pub', keypair_gen.last)

      puts 'Successfully generated','','Keys have been written to the files'
    end

    def write(filename, text)
      File.open(filename, 'w') { |file| file.write(text) }
    end
  end
end
