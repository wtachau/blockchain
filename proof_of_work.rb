require "securerandom"

module ProofOfWork

  def self.generate_proof_of_work(challenge:, work_factor:)
    # Prevent stack overflow
    max_times = 5000000

    attempt = 0
    while attempt < max_times
      token = SecureRandom.hex

      output = Digest::SHA2.hexdigest("#{challenge}||#{token}")

      if Utilities::is_prefixed_with_zeroes(output, work_factor)
        return token
      end
      attempt += 1
    end

    return -1
  end

  def self.verify_proof_of_work(challenge, work_factor, token)
    output = Digest::SHA2.hexdigest("#{challenge}||#{token}")
    return Utilities::is_prefixed_with_zeroes(output, work_factor)
  end
end
