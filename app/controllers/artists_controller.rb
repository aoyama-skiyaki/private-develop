class ArtistsController < ApplicationController
  require 'net/http'
  require 'json'

# GET /artists
  # GET /artists.json
  def index
    @artists = Artist.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @artists }
    end
  end

  # GET /artists/1
  # GET /artists/1.json
  def show
    @artist = Artist.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @artist }
    end
  end

  # GET /artists/new
  # GET /artists/new.json
  def new
    @artist = Artist.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @artist }
    end
  end

  # GET /artists/1/edit
  def edit
    @artist = Artist.find(params[:id])
  end

  # POST /artists
  # POST /artists.json
  def create
    artist_names = params[:artist][:name].split('/')
    artist_names.each do |name|
      @artist = Artist.new({
        name: name
      })
      @artist.save
      get_similar
    end
    respond_to do |format|
      format.html { redirect_to @artist, notice: 'Artist was successfully created.' }
      format.json { render json: @artist, status: :created, location: @artist }
    end
  end

  # PUT /artists/1
  # PUT /artists/1.json
  def update
    @artist = Artist.find(params[:id])

    respond_to do |format|
      if @artist.update_attributes(params[:artist])
        get_similar
        format.html { redirect_to @artist, notice: 'Artist was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @artist.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /artists/1
  # DELETE /artists/1.json
  def destroy
    @artist = Artist.find(params[:id])
    similar_artists = SimilarArtist.where(artist_id: params[:id])
    similar_artists.destroy_all
    @artist.destroy

    respond_to do |format|
      format.html { redirect_to artists_url }
      format.json { head :no_content }
    end
  end

  private

  def get_similar
    # Net::HTTPでリクエストしてAPI叩く
    res = Net::HTTP.get_response(URI.parse(@artist.api_url))
    similars = JSON.parse(res.body)
    unless similars["error"].present?
      similars["similarartists"]["artist"].each do |data| 
        next if data["match"].to_f < 0.3
        similar_artist = SimilarArtist.new({
          artist_id: @artist.id,
          name: data["name"],
          match: data["match"].to_f
        })
        similar_artist.save!
      end
    end
  end
end