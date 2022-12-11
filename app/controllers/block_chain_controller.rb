class BlockChainController < ApplicationController
    #để bảo server đào 1 block mới.
    # 1. Tính toán PoW
    # 2. Trả công cho miner bằng cách thêm 1 transaction đánh dấu việc trả cho chúng ta 1 coin
    # 3. Gắn thêm 1 Block vào chain
    def mine
        # Ta chạy thuật toán để lấy proof tiếp theo ...

        last_block = block_chain.last_block
        last_proof = last_block[:proof]

        proof = block_chain.proof_of_work(last_proof)

        # Nhận lấy phần thưởng cho việc tìm ra proof.
        # sender bằng "0" để kí hiệu rằng node này là dành cho việc đào được coin mới.
        block_chain.new_transaction(
            0,
            "node_identifier", # => Trên thực tế, đây là địa chỉ node của ta
            1
        )

        # Đóng dấu Block mới bằng việc thêm nó vào chain
        previous_hash = BlockChain.hash(last_block)
        block = block_chain.new_block(proof: proof, previous_hash: previous_hash)

        response = {
            message: "New Block forged",
            index: block[:index],
            transactions: block[:transactions],
            proof: block[:proof],
            previous_hash: block[:previous_hash]
        }

        render json: response, status: 200
    end

    #để tạo một transaction mới cho block.
    # {
    #     "sender": "user address",
    #     "recipient": "another address",
    #     "amount": 5
    # }
    def new_transaction
        transaction_params = params.permit(:sender, :recipient, :amount)
        index = block_chain.new_transaction(
            transaction_params[:sender],
            transaction_params[:recipient],
            transaction_params[:amount]
        )

        response = { message: "Transaction will be added to Block #{index}"}

        render json: response, status: 201
    end

    #để trả về Blockchain đầy đủ.
    def full_chain
        response = block_chain.to_json
        render json: response, status: 200
    end

    def register_nodes
        nodes = params[:nodes]
        for node in nodes
            block_chain.register_node(node)
        end

        response = {
            message: 'New nodes have been added',
            total_nodes: block_chain.nodes
        }

        render json: response, status: 200
    end

    def resolve
        replaced = block_chain.resolve_conflicts
        message = replaced ? "Our chain was replaced" : "Our chain is authoritative"

        response = {
            message: message,
            total_nodes: block_chain.nodes
        }

        render json: response, status: 200
    end

    private
    def block_chain
        BlockChain.new
    end

end