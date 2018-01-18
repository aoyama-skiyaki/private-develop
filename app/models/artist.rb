class Artist < ActiveRecord::Base
  attr_accessible :name
  has_many :similar_artists

  BASE_API_URL = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar".freeze
  API_KEY = "ba8ab3885080f2b84bbd6832359f16ad".freeze

  # API実行用のURLを返却
  def api_url
    h = {
      "artist" => name,
      "api_key" => API_KEY,
      "format" => "json"
    }
    BASE_API_URL + "&" + h.map{|k,v| URI.encode(k.to_s) + "=" + URI.encode(v.to_s)}.join("&")
  end
end
