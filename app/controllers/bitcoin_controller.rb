require 'net/http'
require 'json'

class BitcoinController < ApplicationController
  def index
  end

  def price
    currency = params[:currency] || "usd"

    url = URI("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=#{currency}")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)

    render json: {
      price: data["bitcoin"][currency]
    }
  end
end
