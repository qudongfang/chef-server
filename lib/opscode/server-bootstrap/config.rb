module Opscode::ServerBootstrap

  def self.config
    @config ||= Config.new
  end

  def self.configure
    yield config
  end

  module Configurable
    def config
      Opscode::ServerBootstrap.config
    end
  end

  class Config

    # config for writable data
    attr_accessor :output_directory

    # config for db
    attr_accessor :db_driver
    attr_accessor :db_host
    attr_accessor :db_user
    attr_accessor :db_password

    # config for authz
    attr_accessor :bifrost_host
    attr_accessor :bifrost_port
    attr_accessor :bifrost_superuser_id

    attr_accessor :superuser_cert
    attr_accessor :superuser_key

    def to_s
      return <<-EOS
  output_directory:  #{output_directory}

  db_driver:         #{db_driver}
  db_host:           #{db_host}
  db_user:           #{db_user}
  db_password:       #{db_password}

  bifrost_host:        #{bifrost_host}
  bifrost_port:        #{bifrost_port}
  bifrost_superuser:   #{bifrost_superuser_id}

  superuser_cert:    #{superuser_cert}
  superuser_key:     #{superuser_key}
EOS
    end
  end
end
