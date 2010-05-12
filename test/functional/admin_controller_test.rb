require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "actions redirects to login" do
    actions = [:index, :content, :summary, :errors]
    actions.each do |action|
      get action

      assert_response :unauthorized
    end
  end  
  
  test "actions should display pages if logged in" do
    set_http_auth('test', 'test')

    get :index
    assert_response :success
    assert_template 'index'
    
    @import = WordPressImport.new
    @import.shop_url = 'jessetesting.myshopify.com'
    @import.source = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml')
    assert @import.save
    
    get :summary, :id => @import.id
    assert_response :success
    assert_template 'summary'
    
    assert @import = assigns(:import)
    assert_equal @import.id, @import.id
  end
end
