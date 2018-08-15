module Peatio::Command::Service
  class Start < Peatio::Command::Base
    class Ranger < Peatio::Command::Base
      def execute
        if ENV["JWT_PUBLIC_KEY"].nil?
          raise ArgumentError, "JWT_PUBLIC_KEY was not specified."
        end

        key_decoded = Base64.urlsafe_decode64(ENV["JWT_PUBLIC_KEY"])

        jwt_public_key = OpenSSL::PKey.read(key_decoded)
        if jwt_public_key.private?
          raise ArgumentError, "JWT_PUBLIC_KEY was set to private key, however it should be public."
        end

        ::Peatio::Ranger.run!(jwt_public_key)
      end
    end

    subcommand "ranger", "Start ranger process", Ranger
  end

  class Root < Peatio::Command::Base
    subcommand "start", "Start a service", Start
  end
end
