class CreateWidgetLogs < ActiveRecord::Migration
  def self.up
    create_table "widget_logs", :force => true do |t|
      t.integer "count",                  :default => 0, :null => false
      t.string  "widget",                 :limit => 50
      t.string  "referer"
    end
  end

  def self.down
    drop_table "widget_logs"
  end
end
