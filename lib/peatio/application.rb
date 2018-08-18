require 'singleton'

module Peatio
  class Application
    include Singleton

    attr_reader :config

    def initialize
      @config = Peatio::Config.new
    end

    def self.initialize!(env = nil)
      environment = env || ENV.fetch('PEATIO_ENV', 'development')
      require config_path('application')
      require config_path(environment)
      config.env = environment
      self.instance
    end

    def self.path
      File.expand_path('../..', File.dirname(__FILE__))
    end

    def self.config_path(env)
      filename = '%s.rb' % [env]
      config_path = File.join(self.path, 'config', filename)
      unless File.exist?(config_path)
        raise Error.new(code: 100, text: "Invalid config path #{config_path}")
      end
      return config_path
    end

    def self.config
      self.instance.config
    end

    def self.configure
      yield(self.config) if block_given?
    end

  end
end
