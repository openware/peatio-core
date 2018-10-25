module Peatio::Security
  class KeyGenerator

    KeyPair = Struct.new(:private, :public)
    
    def keypair_gen
      OpenSSL::PKey::RSA.generate(2048).yield_self do |pkey|
        KeyPair.new(pkey.to_pem, pkey.public_key.to_pem)
      end
    end

    def output
      puts keypair_gen.private, keypair_gen.public
    end

    def save
      Dir.mkdir('secrets') unless File.exists?('secrets')

      write('secrets/rsa-key', keypair_gen.private)
      write('secrets/rsa-key.pub', keypair_gen.public)

      puts 'Successfully generated','','Keys have been written to the files'
    end

    def write(filename, text)
      File.open(filename, 'w') { |file| file.write(text) }
    end
  end
end
