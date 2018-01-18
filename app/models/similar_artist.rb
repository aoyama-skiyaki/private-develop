class SimilarArtist < ActiveRecord::Base
  attr_accessible :artist_id, :match, :name
  belongs_to :artist
end
