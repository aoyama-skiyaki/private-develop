class ArtistsController < ApplicationController
  require 'net/http'
  require 'json'
  require 'neography'

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

  def output

    #neo4jに接続する
    @neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "neo4j"})

    #ノードを作成する
    Artist.find_each do |artist|
      artist_node = @neo.create_node(name: artist.name) #ノードを登録
      @neo.add_label(artist_node, "Artist") #ラベルを登録
      artist.similar_artists.each do |similar|
        similar_node = first_or_create_node(similar.name)
        # artist_nodeからsimilar_node方向へsimilar関係を追加
        @neo.create_relationship(:similar, artist_node, similar_node)
      end
    end

    respond_to do |format|
      format.html { redirect_to artists_url, notice: 'リレーションを出力しました' }
    end
  end

  def similar
    artist = Artist.find(params[:artist_id])
    # Net::HTTPでリクエストしてAPI叩く
    res = Net::HTTP.get_response(URI.parse(artist.api_url))
    similars = JSON.parse(res.body)
    unless similars["error"].present?
      similars["similarartists"]["artist"].each do |data| 
        next if data["match"].to_f < 0.3
        similar_artist = SimilarArtist.new({
          artist_id: artist.id,
          name: data["name"],
          match: data["match"].to_f
        })
        similar_artist.save!
      end
    end
    respond_to do |format|
      format.html { redirect_to artists_url, notice: '似ているアーティストを取得しました' }
    end
  end

  private
  def first_or_create_node(name)
    similar_node = Neography::Node.find("index", "name", name)
    if similar_node.blank?
      similar_node = @neo.create_node(name: name)
      @neo.add_label(similar_node, "Similar") #ラベルを登録
      @neo.add_node_to_index("index", "name", name, similar_node)
    end
    similar_node
  end

end