require 'digest'

class BlockChain
  attr_accessor :nodes, :chain

  def initialize
    @chain = Array.new
    @current_transactions = Array.new
    @nodes = Set[] #điều này sẽ giúp danh sách các node là uniq

    new_block(previous_hash: 1, proof: 100)
  end

  # block = {
  #   'index': 1,
  #   'timestamp': 1506057125.900785,
  #   'transactions': [
  #       {
  #           'sender': "8527147fe1f5426f9dd545de4b27ee00",
  #           'recipient': "a77f5cdfa2934df3954a5c7c7da5df1f",
  #           'amount': 5,
  #       }
  #   ],
  #   'proof': 324984774000,
  #   'previous_hash': "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  # }

  #create new block into chain
  def new_block(proof:, previous_hash: nil)
    block = {
      index: chain.length + 1,
      timestamp: Time.current,
      transactions: @current_transactions,
      proof: proof,
      previous_hash: previous_hash || self.class.hash(chain[-1])
    }

    @current_transactions = Array.new
    chain << block
    return block
  end

  #create new transaction into list transactions
  def new_transaction(sender, recipient, amount)
    @current_transactions << {
      sender: sender,
      recipient: recipient,
      amount: amount
    }

    return last_block[:index] + 1
  end

  #Thuật toán proof of work (PoW) là cách mà một Block mới được tạo hoặc được mined (đào).
  def proof_of_work(last_proof)
    #Nếu muốn điều chỉnh độ khó của thuật toán, ta có thể thay đổi số lượng số 0 cần validate
    proof = 0
    while !self.class.valid_proof(last_proof, proof)
      proof += 1
    end
    return proof
  end

  #return last block of chain
  def last_block
    chain[-1]
  end

  def register_node(address)
    nodes << address
  end

  # Đây là thuật toán Consensus của ta: nó sẽ thực hiện bằng cách thay thế chain của ta bằng chain dài nhất trong network
  # Trả về true nếu chain hiện tại bị thay thế
  def resolve_conflicts
    new_chain = nil
    max_length = chain.length # tính toán độ dài chain dài nhất, khởi đầu là chain hiện tại
    for node in nodes
      response = Net::HTTP.new(node).request # => For DEMO purporse: implement request để lấy chain hàng xóm được rút ngắn :)
      length = response[:length]
      chain = response[:chain]

      if (length > max_length && self.class.valid_chain(chain)) # Nếu chain hàng xóm dài hơn của ta và valid => thay thế
        max_length = length
        new_chain = chain
      end
    end

    # Cuối cùng, trả về true nếu chain hiện tại bị thay thế, trả về false nếu ngược lại
    if new_chain
      chain = new_chain
      return true
    end

    return false
  end

  class << self
    #return hash of block
    def hash(block)
      Digest::SHA256.hexdigest(block.to_json)
    end

    #Tìm một số p mà khi hash nó cùng với kết quả của block trước đó, sẽ trả ra 1 hash mới với 4 số 0 đứng đầu
    def valid_proof(last_proof, proof)
      guess = "#{last_proof}#{proof}"
      guess_hash = Digest::SHA256.hexdigest(guess.to_json)
      return guess_hash[0..3] == "0000"
    end

    def valid_chain(chain)
      last_block = chain[0]
      current_index = 1

      while current_index < chain.length
        block = chain[current_index]

        # Kiểm tra xem hash của block có chính xác không ?
        return false if block[:previous_hash] != self.class.hash(last_block)

        # Kiểm tra xem Proof of Work có chính xác
        return false unless self.class.valid_proof(last_block[:proof], block[:proof])

        last_block = block
        current_index += 1
      end

      return true
    end

  end

end