Rails.application.routes.draw do
  root 'bitcoin#index'
  get 'bitcoin/preco', to: 'bitcoin#preco'
end
