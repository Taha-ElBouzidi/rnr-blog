class AddPublishedByToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :published_by_id, :integer
    add_index :posts, :published_by_id
  end
end
