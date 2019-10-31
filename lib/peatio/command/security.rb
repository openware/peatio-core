# frozen_string_literal: true

module Peatio::Command
  class Security < Peatio::Command::Base
    class KeyGenerator < Peatio::Command::Base
      option "--print", :flag, "print on screen"
      option "--path", "FOLDER", "save keypair into folder", default: "secrets"

      def execute
        keypair = Peatio::Security::KeyGenerator.new

        if print?
          puts keypair.private, keypair.public
          puts "-----BASE64 ENCODED-----"
          puts Base64.urlsafe_encode64(keypair.public)
        else
          begin
            keypair.save(path)
            puts "Files saved in #{File.join(path, 'rsa-key')}"
          rescue IOError => e
            abort("Failed saving files")
          end
        end
      end
    end

    subcommand "keygen", "Generate a public private rsa key pair", KeyGenerator
  end
end
