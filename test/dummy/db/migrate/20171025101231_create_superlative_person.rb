class CreateSuperlativePerson < ActiveRecord::Migration[5.0]
  def change
    create_table :superlative_people do |t|
      t.string :name

      t.timestamps
    end
  end
end
