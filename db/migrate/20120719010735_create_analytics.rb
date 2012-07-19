class CreateAnalytics < ActiveRecord::Migration
  def self.up
    create_table :analytics do |t|
      t.string :segment
      t.string :action
      t.string :slice
      t.string :ip
      t.integer :user
      t.text :params

      t.timestamps
    end
  end

  def self.down
    drop_table :analytics
  end
end
