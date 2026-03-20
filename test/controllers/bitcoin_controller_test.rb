require "test_helper"

class BitcoinControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get bitcoin_index_url
    assert_response :success
  end
end
