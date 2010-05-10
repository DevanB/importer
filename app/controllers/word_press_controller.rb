class WordPressController < ApplicationController

  around_filter :shopify_session

  def index
    redirect_to :action => 'new'
  end
  
  def new
  end

  def create
    begin
      @import = WordPressImport.new(params[:import])
      @import.shop_url = current_shop.url

      if @import.save
        @import.guess
      else
        flash[:error] = "Error importing your blog."
        render :action => "new"
      end
    end
  end

  def import
    # Find the import job 
    begin
      @import = WordPressImport.find(params[:id])
      raise ActiveRecord::RecordNotFound if @import.shop_url != current_shop.url

      @import.update_attribute :submitted_at, Time.now
      @import.send_later(:execute!, session[:shopify].site, Import.email_address)
    rescue ActiveRecord::RecordNotFound => e
      flash[:error] = "Either the import job that you are attempting to run does not exist or you are attempting to run someone else's import job..."
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'index' }
      format.js do
        render(:update) { |page| page['confirm'].replace :partial => 'import' }
      end
    end
  end
  
  def poll
    @import = WordPressImport.find(params[:import_id])

    render(:update) { |page| page['confirm'].replace :partial => 'import' }
  end
  
end
