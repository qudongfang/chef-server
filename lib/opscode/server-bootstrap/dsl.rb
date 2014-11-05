######################################################################
# the dsl module
######################################################################

require 'openssl'
require 'restclient'
require 'json'
require 'opscode/server-bootstrap/database_helper'
require 'opscode/server-bootstrap/logger'
require 'opscode/server-bootstrap/models/superuser'

module Opscode::ServerBootstrap
  module DSL

    include Opscode::ServerBootstrap::Configurable
    include Opscode::ServerBootstrap::DatabaseHelper
    include Opscode::ServerBootstrap::Loggable

    GLOBAL_PLACEHOLDER_ORG_ID = "00000000000000000000000000000000"

    #
    # user-related dsl
    #
    def superuser
      log "Creating the superuser..."
      su = Opscode::ServerBootstrap::Models::Superuser.new
      yield su
      su.create
    end

    def superuser_cert
      cert_file = File.read(config.superuser_cert)
      OpenSSL::X509::Certificate.new(cert_file)
    end

    def superuser_key
      key_file = File.read(config.superuser_key)
      OpenSSL::PKey::RSA.new(key_file)
    end

    #
    # general use methods
    # TODO: some of these probably shouldn't be here and we should
    # consider moving this out to a separate module
    #
    def create_credentials_dir
      log "Creating the credentials directory..."
      unless Dir.exists?(config.output_directory)
        Dir.mkdir(config.output_directory)
      end
    end

    def truncate_sql_tables
      log "Truncating the sql tables..."
      db[:users].truncate
    end

    def create_container_in_authz(name, requester_id)
      url = "http://#{config.bifrost_host}:#{config.bifrost_port}/containers"
      headers = {
        :content_type => :json,
        :accept => :json,
        'X-Ops-Requesting-Actor-Id' => requester_id
      }

      result = RestClient.post(url, "{}", headers)
      JSON.parse(result)["id"]
    end

    def create_global_containers(superuser_authz_id)
      %w(organizations users).each do |name|
        authz_id = create_container_in_authz(name, superuser_authz_id)

        created_time = Time.now.utc
        db[:containers].insert(:name => name, :id => authz_id, :org_id => GLOBAL_PLACEHOLDER_ORG_ID, :last_updated_by => superuser_authz_id, :authz_id => authz_id, :created_at => created_time.to_s[0..18], :updated_at => created_time.to_s[0..18])
      end
    end
  end
end
