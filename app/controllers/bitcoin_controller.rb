class BitcoinController < ApplicationController
  require 'net/http'
  require 'json'

  def index
  end

  def preco
    moeda = params[:moeda] || "brl"
    url = URI("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=#{moeda}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(url)
    request["User-Agent"] = "BitcoinMonitor/1.0"

    resposta = http.request(request)
    dados = JSON.parse(resposta.body)
    preco = dados["bitcoin"][moeda]

    respond_to do |format|
      format.json { render json: { preco: preco } }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { erro: e.message }, status: :service_unavailable }
    end
  end
end
