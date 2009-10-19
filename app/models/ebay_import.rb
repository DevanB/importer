# == Schema Information
# Schema version: 20081117161638
#
# Table name: imports
#
#  id              :integer(11)     not null, primary key
#  created_at      :datetime
#  updated_at      :datetime
#  content         :text(2147483647
#  start_time      :datetime
#  finish_time     :datetime
#  shop_url        :string(255)
#  adds            :text
#  guesses         :text
#  type            :string(255)
#  base_url        :string(255)
#  submitted_at    :datetime
#  import_errors   :text
#  ebay_account_id :integer(11)
#

class EbayImport < Import
  belongs_to :ebay_account

  def build_item(item)
    builder = ProductBuilder.new(
      :title => item.title,
      :body => "<notextile>#{EbayImport.get_item_description(item)}</notextile>",
      :vendor => 'None provided',
      :product_type => (item.primary_category.category_name.split(/[,:]/).first || 'None provided'),
      :tags => item.primary_category.category_name.split(/[,:]/).join(","),
      :variants => [
        ShopifyAPI::Variant.new(
          :title => 'Default',
          :price => item.start_price,
          :sku => item.sku,
          :inventory_management => 'shopify',
          :inventory_quantity => item.quantity
        )
      ],
      :images => [
        images_for(item)
      ]
    )
    
    builder
  end
  
  def save_builder(builder)
    if builder.save
      self.added('product')
    else
      self.import_errors << builder.errors
    end
  end
  
  def parse
  end
  
  def save_data
    current_page = 1

    begin
      response = ebay_account.ebay.get_my_ebay_selling(
        :active_list => Ebay::Types::ItemListCustomization.new(
          :pagination => Ebay::Types::Pagination.new( :entries_per_page => 25, :page_number => current_page )
        )
      )

      response.active_list.items.each do |item|
        item_response = ebay_account.ebay.get_item(:item_id => item.item_id)
        save_builder build_item(item_response.item)
      end rescue nil
    
      current_page += 1
    end while response.active_list.pagination_result.total_number_of_pages > current_page
  end
  
  private 
  def images_for(item)
    # multiple images?

    return if item.picture_details.picture_url.blank?
    ShopifyAPI::Image.new(:src => item.picture_details.picture_url)
  end
  
  def EbayImport.get_item_description(item)
    response = Net::HTTP.get(
      URI.parse(
        "http://open.api.ebay.com/shopping?callname=GetSingleItem&responseencoding=XML&appid=#{Ebay::Api.app_id}&siteid=0&version=515&ItemID=#{item.item_id}&includeSelector=Description"
      )
    )
    
    REXML::XPath.first(REXML::Document.new(response), "/GetSingleItemResponse/Item/Description").text rescue nil    
  end
  
end
