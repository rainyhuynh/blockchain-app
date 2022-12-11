Rails.application.routes.draw do
  namespace :block_chain do
    get :mine
    post :new_transaction
    get :full_chain
    post :register_nodes
    get :resolve
  end

end
