class AddContentBackToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :content, :text
  end

  def self.down
    remove_column :imports, :content
  end
end
