# encoding: utf-8
class PlaylistsController < ApplicationController
  # GET /playlists
  # GET /playlists.json
  def index
    @playlists = Playlist.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @playlists }
    end
  end

  # GET /playlists/1
  # GET /playlists/1.json
  def show
    @playlist = Playlist.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @playlist }
    end
  end

  # GET /playlists/new
  # GET /playlists/new.json
  def new
    @playlist = Playlist.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @playlist }
    end
  end

  # GET /playlists/1/edit
  def edit
    @playlist = Playlist.find(params[:id])
  end

  # POST /playlists
  # POST /playlists.json
  def create
    @playlist = Playlist.new(params[:playlist])

    respond_to do |format|
      if @playlist.save
        format.html { redirect_to @playlist, notice: 'Playlist was successfully created.' }
        format.json { render json: @playlist, status: :created, location: @playlist }
      else
        format.html { render action: "new" }
        format.json { render json: @playlist.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /playlists/1
  # PUT /playlists/1.json
  def update
    @playlist = Playlist.find(params[:id])

    respond_to do |format|
      if @playlist.update_attributes(params[:playlist])
        format.html { redirect_to @playlist, notice: 'Playlist was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @playlist.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /playlists/1
  # DELETE /playlists/1.json
  def destroy
    @playlist = Playlist.find(params[:id])
    @playlist.destroy

    respond_to do |format|
      format.html { redirect_to playlists_url }
      format.json { head :no_content }
    end
  end 

  def get_list

  end

  def generate
    require 'open-uri'

    @output = []

    #Create a new playlist we'll be returning statuses to.
    @playlist = Playlist.new
    @playlist.input_string = params['playlists']
    @playlist.save!

    i = 0;

    #queue up each line:
    params['playlists'].each_line do |line|
      i += 1
      # queue up for processing
      TrackLookup.perform_async(line, @playlist.id, i)
      
    end

    #save the number of tracks so we can be sure it's finished.
    @playlist.num_tracks = i
    @playlist.status = "SUBMITTED"
    @playlist.save!

    redirect_to :action => 'wait', :id => @playlist.id

  end

  # 
  # This page will check to see if processing is done and if not reload itself.
  # 
  # @return [type] [description]
  def wait
    @playlist = Playlist.find(params[:id])

    if @playlist.tracks and @playlist.tracks.length == @playlist.num_tracks
      redirect_to :action => 'show', :id => @playlist.id
    else

      respond_to do |format|
        format.html
        format.json { render json: @playlist }
      end
    end

  end

end
