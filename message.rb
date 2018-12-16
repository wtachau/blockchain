class Message

  attr_accessor :uuid, :port, :payload, :version, :ttl, :to_hash, :type

  def initialize(uuid: nil, type: "", port:, payload: {})
    @uuid = uuid || SecureRandom.uuid
    @port = port
    @payload = payload
    @type = type
    @ttl = 246
  end

  def to_hash
    {
      uuid: @uuid,
      port: @port,
      payload: @payload,
      type: @type.to_s,
      ttl: @ttl
    }
  end

  def self.from_params(params:)
    type = ""
    if !params["type"].empty?
      type = Module.const_get(params["type"])
    end

    return self.new(
      uuid: params["uuid"],
      port: params["port"].to_i,
      type: type,
      payload: params["payload"]
    )
  end
end
