class HealthCheck
  include ChefResource

  REACHABLE = 'reachable'.freeze
  TIMEOUT = 'timeout'.freeze
  UNREACHABLE = 'unreachable'.freeze
  ERRORING = 'erroring'.freeze
  KEYERROR = 'key error'.freeze

  attr_reader :status, :erchef, :postgres

  def initialize
    @status = nil
    @erchef = { status: REACHABLE }
    @postgres = { status: REACHABLE }
  end

  #
  # Do a general health check.
  #
  def check
    erchef_health
    erchef_authentication
    postgres_health
    overall
  end

  private

  #
  # Try to ping erchef as an indicator of general health
  #
  def erchef_health
    erchef_health_metric do
      chef.get_rest 'license'
    end
  end

  #
  # Try to authenticate with erchef to prove that oc-id is actually functioning
  #
  # TODO: in order for this to work, we need a test user, with
  # username/password stored in the vault and accessible in Settings
  #
  def erchef_authentication
  end

  #
  # Check the number of active Postgres connections as an indicator of
  # general health
  #
  def postgres_health
    begin
      ActiveRecord::Base.connection.query(
        'SELECT count(*) FROM pg_stat_activity'
      ).flatten.first.to_i.tap do |connections|
        @postgres[:connections] = connections
      end
    rescue ActiveRecord::ConnectionTimeoutError
      @postgres[:status] = TIMEOUT
    rescue PG::ConnectionBad
      @postgres[:status] = UNREACHABLE
    end
  end

  #
  # What is the overall system status
  #
  def overall
    if @postgres[:status] == REACHABLE &&
       @erchef[:status] == REACHABLE
      @status = 'ok'
    else
      @status = 'not ok'
    end
  end

  def erchef_health_metric
    begin
      yield
    rescue Errno::ETIMEDOUT
      @erchef[:status] = TIMEOUT
    rescue Net::HTTPServerException => e
      if e.message =~ /401/
        @erchef[:status] = KEYERROR
      else
        @erchef[:status] = ERRORING
      end
    end
  end
end
