require "colorize"
require "faraday"

require_relative "constants"

module Utilities

  ####################
  # String Utilities #
  ####################

  def self.is_prefixed_with_number(string, prefix, number)
    return string[0..(number - 1)].split("").all? { |c| c == prefix }
  end

  def self.is_prefixed_with_zeroes(string, number)
    return is_prefixed_with_number(string, "0", number)
  end

  def self.fixed_length(string, length)
    if !string
      return "-" * (length - 1)
    end
    (string.length > length) ? string.slice(0..length - 4) + "..." : string.ljust(length, " ")
  end


  ########################
  # Networking Utilities #
  ########################

  def self.get_peers(nodes:)
    nodes.select(&:is_peer)
  end

  def self.check_for_eviction(nodes:)
    peers = Utilities::get_peers(nodes: nodes)
    if peers.count > Constants::MAX_PEERS_COUNT
      peer_to_remove = peers.sample
      peer_to_remove.is_peer = false
    end
  end

  def self.send_message_to_peers(message:, peers:)
    peers.each do |peer|
      Utilities::log "Sending message #{message.uuid} to port #{peer.port}".light_blue

      Utilities::make_request(
        port: peer.port,
        path: "gossip",
        body: message.to_hash,
        post: true
      )
    end
  end

  def self.make_request(port:, path:, body: nil, post: false)
    url = "http://localhost:#{port}/#{path}"

    begin
      if post
        response = Faraday.new(url: url).post do |f|
          f.headers['Content-Type'] = 'application/json'
          f.body = body.to_json.force_encoding(Encoding::UTF_8)
        end

        return response.body
      else
        Faraday.get(url).body
      end
    rescue Errno::ECONNREFUSED => e
      puts e
    end
  end

  #####################
  # Logging Utilities #
  #####################

  def self.log(string)
    puts "[#{Time.now}] " + string.to_s
  end


  ##################
  # Math Utilities #
  ##################

  def self.is_power_of_two(number:)
    number.to_s(2).count("1") == 1
  end

  def self.next_highest_power_of_two(number:)
    return 1 if number == 0
    return 2 ** Math.log2(number).ceil
  end

end
