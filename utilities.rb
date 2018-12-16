require "faraday"

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

  def self.log(string)
    puts "[#{Time.now}] " + string.to_s
  end
end
