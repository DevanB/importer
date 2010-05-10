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
require 'nokogiri'
require 'open-uri'

class WordPressImport < Import
  validate_on_create :has_source
  
  def blog_title
    @blog_title ||= xml.xpath('rss/channel/title').first.text    
  end
  
  def original_url
    @original_url ||= xml.xpath('rss/channel/link').first.text
  end
    
  def guess
    # Loop through each <item> tag in the file
    xml.xpath('rss/channel/item').each do |node|
      status_node = node.children.select {|e| e.name == "status" }.first
      next unless status_node
      
      status = status_node.text
      comments = node.children.select {|e| e.name == "comment" }
      
      case node.children.find {|e| e.name == "post_type" }.text
      when 'page'
        self.guessed('page')
      when 'post'
        self.guessed('article') if status == 'publish' || status == 'draft'
        comments.each { |c| self.guessed('comment') }
      end      
    end
    
  rescue Nokogiri::SyntaxError => e
    self.import_errors << e.message
  end
    
  def parse
    # Loop through each <item> tag in the file
    xml.xpath('rss/channel/item').each do |node|
      status_node = node.children.select {|e| e.name == "status" }.first
      next unless status_node

      post_type_node = node.children.find {|e| e.name == "post_type" }
      next unless post_type_node
      
      case post_type_node.text
      when 'page'
        add_page(node)
      when 'post'
        add_article(node)        
      end      
    end
  end
  
  def save_data
    pages.each do |p|
      current_saved_date = p.published_at
      p.save
      
      p.published_at = current_saved_date
      if p.save
        added('page')
      end
    end

    blog.title = "#{ShopifyAPI::Shop.current.name} blog" if blog.title.blank?
    
    blog.save    
    articles.each do |a|  
      current_saved_date = a.published_at
      a.prefix_options[:blog_id] = blog.id
      a.save
      
      a.published_at = current_saved_date
      if a.save
        added('article')
      end
    end
    
    # comments is a hash of [ShopifyAPI::Comment => ShopifyAPI::Article]
    comments.each do |comment, article|
      comment.blog_id = blog.id
      comment.article_id = article.id
      if comment.save
        added('comment')
      end
    end
  end
  
  private  
  def xml
    @xml ||= Nokogiri::XML(self.source.to_file.read.gsub(' & ', ' &amp; '))
  end
  
  def pages
    @pages ||= Array.new
  end

  def articles
    @articles ||= Array.new
  end

  def comments
    @comments ||= Hash.new
  end
  
  def blog
    @blog ||= ShopifyAPI::Blog.new(:title => blog_title)
  end
  
  def add_page(node)
    get_attributes(node)    
    pages << ShopifyAPI::Page.new( :title => @title, :body => @body, :author => @author, :published_at => @pub_date )
  end
  
  def add_article(node)
    get_attributes(node)
    
    if @status == 'publish'
      article = ShopifyAPI::Article.new( :title => @title, :body => @body, :author => @author, :published_at => @pub_date )
      articles << article
    elsif @status == 'draft'
      article = ShopifyAPI::Article.new( :title => @title, :body => @body, :author => @author, :published_at => 0 )
      articles << article
    end
    
    add_comments(node.children.select {|e| e.name == "comment" } , article)
  end
  
  def add_comments(nodes, article)
    blog.commentable = 'yes' unless blog.comments_enabled?
    
    nodes.each do |comment_node|
      # We have to add a prefix from the root node so that REXML is happy
      comment_string = comment_node.to_s.gsub('<wp:comment>', "<wp:comment xmlns:wp='http://wordpress.org/export/1.0/'>")

      # New XML doc starting at the root of the comment
      @comment_root_node = Nokogiri::XML(comment_string).children.first

      author = @comment_root_node.children.select { |e| e.name == "comment_author" }.first.text
      email = @comment_root_node.children.select { |e| e.name == "comment_author_email" }.first.text
      body = @comment_root_node.children.select { |e| e.name == "comment_content" }.first.text
      pub_date = @comment_root_node.children.select { |e| e.name == "comment_date" }.first.text
      
      email = 'blank@blank.com' if email.blank?

      comments[ShopifyAPI::Comment.new( :body => body, :author => author, :email => email, :published_at => pub_date )] = article
    end    
  end
  
  def get_attributes(node)
    @status = node.children.select {|e| e.name == "status" }.first.text
    @title = node.children.select {|e| e.name == "title" }.first.text
    @body = node.children.select {|e| e.name == "encoded" }.first.text
    @pub_date = DateTime.parse(node.children.find {|e| e.name == "post_date" }.text).strftime('%F %T') if @status == 'publish'
    @author = node.children.find {|e| e.name == "creator" }.text
  end
end
