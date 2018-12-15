class Message

  attr_accessor :uuid, :port, :payload, :version, :ttl, :to_hash

  def initialize(uuid: nil, version: 1, port:, payload: {})
    @uuid = uuid || SecureRandom.uuid
    @version = version
    @port = port
    @payload = payload
    @ttl = 246
  end

  def to_hash
    {
      uuid: @uuid,
      version: @version,
      port: @port,
      payload: @payload,
      ttl: @ttl
    }
  end

  def self.from_params(params:)
    return self.new(
      uuid: params["uuid"],
      version: params["version"],
      port: params["port"].to_i,
      payload: params["payload"]
    )
  end
end
