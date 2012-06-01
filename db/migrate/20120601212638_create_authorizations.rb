class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.string :provider
      t.string :u_id
      t.integer :user_id

      t.timestamps
    end
  end
end
