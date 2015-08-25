class ChangeSliceColumnName < ActiveRecord::Migration
  def change
    rename_column :analytics, :slice, :bp_slice
  end
end
