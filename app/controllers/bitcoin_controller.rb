class BitcoinController < ApplicationController
  require 'net/http'
  require 'json'

  ALLOWED_CURRENCIES = %w[usd brl eur].freeze
  DEFAULT_FALLBACK_PRICE = {
    "brl" => 350_000.0,
    "usd" => 65_000.0,
    "eur" => 60_000.0
  }.freeze

  before_action :disable_cache

  def index
  end

  def preco
    moeda = params[:moeda].to_s.downcase.gsub(/[^a-z]/, "")
    moeda = "brl" if moeda.blank?
    moeda = "brl" unless ALLOWED_CURRENCIES.include?(moeda)

    cache_key = "bitcoin_price_#{moeda}"
    preco, fonte = buscar_preco_coingecko(moeda)

    Rails.cache.write(cache_key, preco, expires_in: 10.minutes)
    render json: { preco: preco, fonte: fonte }
  rescue => e
    begin
      preco_fallback, fonte_fallback = buscar_preco_coinbase(moeda)
      Rails.cache.write(cache_key, preco_fallback, expires_in: 10.minutes)
      return render json: { preco: preco_fallback, warning: "fonte_secundaria", erro: e.message, fonte: fonte_fallback }
    rescue
    end

    preco_cache = Rails.cache.read(cache_key)

    if preco_cache.present?
      render json: { preco: preco_cache, warning: "valor_em_cache", erro: e.message, fonte: "cache" }
    else
      render json: { preco: DEFAULT_FALLBACK_PRICE[moeda], warning: "fallback_local", erro: e.message, fonte: "local" }
    end
  end

  private

  def disable_cache
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def buscar_preco_coingecko(moeda)
    url = URI("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=#{moeda}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 8

    request = Net::HTTP::Get.new(url)
    request["User-Agent"] = "BitcoinMonitor/1.0"
    request["Accept"] = "application/json"

    resposta = http.request(request)
    raise "Falha API (#{resposta.code})" unless resposta.is_a?(Net::HTTPSuccess)

    dados = JSON.parse(resposta.body)
    preco = dados.dig("bitcoin", moeda)
    raise "Preço indisponível" if preco.blank?

    [preco, "coingecko"]
  end

  def buscar_preco_coinbase(moeda)
    par = "BTC-#{moeda.upcase}"
    url = URI("https://api.coinbase.com/v2/prices/#{par}/spot")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 8

    request = Net::HTTP::Get.new(url)
    request["User-Agent"] = "BitcoinMonitor/1.0"
    request["Accept"] = "application/json"

    resposta = http.request(request)
    raise "Falha API secundária (#{resposta.code})" unless resposta.is_a?(Net::HTTPSuccess)

    dados = JSON.parse(resposta.body)
    preco = dados.dig("data", "amount")
    raise "Preço indisponível na API secundária" if preco.blank?

    [preco.to_f, "coinbase"]
  end
end
