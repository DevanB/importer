require 'test_helper'

class ImportTest < ActiveSupport::TestCase
  
  def setup
    @file = File.new(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml')

    @import = WordPressImport.new(:source => @file)
    @import.shop_url = 'localhost.myshopify.com'
    @import.save!    
  end
    
  def test_should_be_able_to_add_and_guess
    hashes = [@import.adds, @import.guesses]
    
    hashes.each do |hash|
      assert_equal Hash.new, hash
    end
    
    @import.added('post')
    @import.added('page')
    @import.save

    @import.guessed('post')
    @import.guessed('page')
    @import.source = 't'
    @import.save

    [@import.reload.adds, @import.guesses].each do |hash|
      assert_equal 1, hash['post']
      assert_equal 1, hash['page']
    end
    
    assert @import.save
  end
    
  def test_should_not_allow_creation_of_import_without_source
    @import = WordPressImport.new
    assert !@import.save
  end
  
  def test_should_not_save_without_site
    @import = WordPressImport.new( :source => File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press/word_press_import.xml') )
    assert !@import.save
    
    @import.shop_url = "http://testing.com"
    assert @import.save
  end
  
  def test_start_time_and_finish_time
    start = 5.minutes.ago
    @import.start_time = start
    assert_equal start, @import.start_time
    
    finish = Time.now
    @import.finish_time = finish
    assert_equal finish, @import.finish_time
  end
  
  def test_should_finish_if_error_is_thrown
    @import.stubs(:parse).raises(StandardError, 'problem')
    
    assert_nil @import.finish_time
    @import.execute!('localhost', 'bill@bob.com')
    assert @import.reload.finish_time
    assert @import.finished?
  end
    
  def test_shop_url_should_be_protected
    @import = WordPressImport.new(:shop_url => 'test', :source => @file)
    assert !@import.save
    
    @import.shop_url = 'test'
    assert @import.save
  end
  
  def test_adds_should_have_sensible_default
    @import = WordPressImport.new(:shop_url => 'test', :source => @file)
    @import.shop_url = 'test'
    assert @import.save
    assert_equal(Hash.new, @import.adds)
    assert_equal(Hash.new, @import.guesses)
  end
  
  def test_delete_source_after_finished
    @import = WordPressImport.new(:shop_url => 'test', :source => @file)
    @import.shop_url = 'test'
    assert @import.save
    
    assert !@import.finished?
    assert @import.source.exists?
    
    @import.finish_time = Time.now
    @import.save!
    
    assert @import.finished?
    assert !@import.reload.source.exists?
  end
end
