require 'test_helper'

class EbayImportTest < ActiveSupport::TestCase
  def setup
    @import = EbayImport.new

    @import.shop_url = 'shopify.myshopify.com'
@import.save!
# puts @import.errors.full_messages
  end
  
  test "execute should run everything" do
    @import.expects(:parse)
    @import.expects(:save_data)

    assert_difference "ActionMailer::Base.deliveries.size" do
      @import.execute!('user:pass.shopify.myshopify.com', 'shop@shopify.com')
    end

    assert_equal ['shop@shopify.com'], ActionMailer::Base.deliveries.first.to
  end
end