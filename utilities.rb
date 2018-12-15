module Utilities

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

  def self.make_request(url:, body: nil, post: false)
    begin
      if post
        HTTParty.post(url, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
      else
        HTTParty.get(url)
      end
    rescue Errno::ECONNREFUSED => e
      puts e
    end
  end
end
