require_relative "../utilities"

module NodeService

  def self.add_node_if_missing(nodes:, port:)
    node = nodes.find { |node| node.port == port }

    if !node
      new_node = Node.new(
        port: port,
        is_peer: true
      )
      nodes.push(new_node)
      Utilities::check_for_eviction(nodes: nodes)
    end
  end

  def self.render_peers(nodes:, me:)
    (Utilities::get_peers(nodes: nodes) + [me]).map(&:display_hash).to_json
  end

  def self.update_nodes_from_message(nodes:, message:)
    # Update our state based on the message content.
    #  If we know of this peer already, update it, otherwise add it to our list of peers
    node = nodes.find { |node| node.port == message.port }

    if node
      node.last_heard_from = Time.now
    else
      new_node = Node.new(
        port: message.port,
        is_peer: true
      )

      nodes.push(new_node)
      Utilities::check_for_eviction(nodes: nodes)
    end
  end
end
