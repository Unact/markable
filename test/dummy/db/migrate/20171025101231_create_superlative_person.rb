class CreateSuperlativePerson < ActiveRecord::Migration
  def change
    create_table :superlative_people do |t|
      t.string :name

      t.timestamps
    end
  end
end
