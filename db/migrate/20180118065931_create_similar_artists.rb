class CreateSimilarArtists < ActiveRecord::Migration
  def change
    create_table :similar_artists do |t|
      t.integer :artist_id
      t.string :name
      t.integer :match

      t.timestamps
    end
  end
end
