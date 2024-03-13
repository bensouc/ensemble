class RenameTypeToRythmFromSubscription < ActiveRecord::Migration[7.0]
  def change
    rename_column :subscriptions, :type, :rythm
  end
end
