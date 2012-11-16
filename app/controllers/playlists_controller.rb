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

    api_key = "AKIAIJGC6M6FDMR3IYYA"
    api_secret = "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"

    @output = []

    params['playlists'].each_line do |line|
      sleep(1)
      
      track_id = line.strip.split('/').last

      #contact spotify's API
      @output << {'spotify' => nil, 'amazon' => nil}

      url = "http://ws.spotify.com/lookup/1/?uri=spotify:track:#{track_id}"
      @output.last['url'] = url

      puts url

      begin
        response = open(url).read 
      rescue
        puts "Couldn't process #{url}"
        puts $!
        next
      end

      results = Hash.from_xml(response)

      #sometimes spotify returns an array for artist, just grab the first one
      if results['track']['artist'].kind_of?(Array)
        results['track']['artist'] = results['track']['artist'][0]
      end

      @output.last['spotify'] =results

      req = Vacuum.new
      req.configure key:    api_key,
                    secret:  api_secret,
                    tag:    'robotpolisher-20'

      res = req.get query: { 'Operation'   => 'ItemSearch',
                             'SearchIndex' => 'MP3Downloads',
                             'ResponseGroup' => 'ItemAttributes,Tracks,Images',
                             'Keywords'    =>  results['track']['name'] + "  " + results['track']['artist']['name']  + " " + results['track']['album']['name']
                            }

      song_file = Hash.from_xml(res.body)
      num_found = song_file['ItemSearchResponse']['Items']['TotalResults']


     unless  song_file['ItemSearchResponse']['Items']['Item'].nil?


        if song_file['ItemSearchResponse']['Items']['Item'].kind_of?(Array)
          @output.last['amazon'] = song_file['ItemSearchResponse']['Items']['Item'].last
          puts "array"
        else
          @output.last['amazon'] = song_file['ItemSearchResponse']['Items']['Item']
          puts "not array "
        end
      else
          puts "not found by amazon #{results['track']['name'] }"
      end


    end


    @theout = @output
  end

end
