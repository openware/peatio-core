module Peatio::Command
  class Security < Peatio::Command::Base
    class KeyGenerator < Peatio::Command::Base
      option "--save", :flag, "save public private rsa key pair to file"

      def execute
        key_generator = Peatio::Security::KeyGenerator.new
        save? ? key_generator.save : key_generator.output
      end
    end

    subcommand "keygen", "Generate a public private rsa key pair", KeyGenerator
  end
end
