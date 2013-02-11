class TrackLookup
  include Sidekiq::Worker
  require 'open-uri'


  sidekiq_options :queue => :spotlist
  # sidekiq_options :retry => false

  def perform(line, playlistid, i)

    @api_key = "AKIAIJGC6M6FDMR3IYYA"
    @api_secret = "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"

    #grab the right playlist and append the results
    playlist = Playlist.find(playlistid)

    puts "HERE!"

    if rand(10) == 1
      sleep(10) #throttle to avoid hitting the max limit...
    end
      
    track_id = line.strip.split('/').last

    #contact spotify's API
    output = {'spotify' => nil, 'amazon' => [], 'error' => ""}

    url = "http://ws.spotify.com/lookup/1/?uri=spotify:track:#{track_id}"
    output['url'] = url

    # if we can't process that URL we stop here
    begin
      response = open(url).read 
    rescue Exception => e
      puts "Couldn't Process #{e}"

      output['error'] = "Couldn't process #{url} : #{e}"
      playlist.add_to_set(:tracks, output)
      playlist.save
      return
    end

    # parse the XML returned
    results = Hash.from_xml(response)

    #sometimes spotify returns an array for artist, just grab the first one
    if results['track']['artist'].kind_of?(Array)
      results['track']['artist'] = results['track']['artist'][0]
    end

    #save the spotify results
    output['spotify'] = results

    #now hit Amazon with that information.
    req = Vacuum.new
    req.configure key:    @api_key,
                  secret:  @api_secret,
                  tag:    'robotpolisher-20'

    res = req.get query: { 'Operation'   => 'ItemSearch',
                           'SearchIndex' => 'MP3Downloads',
                           'ResponseGroup' => 'ItemAttributes,Tracks,Images',
                           'Keywords'    =>  results['track']['name'].force_encoding('utf-8') + "  " + results['track']['artist']['name'].force_encoding('utf-8')
                          }

    song_file = Hash.from_xml(res.body.force_encoding('utf-8'))
    num_found = song_file['ItemSearchResponse']['Items']['TotalResults']

    #was found on amazon?
    unless  song_file['ItemSearchResponse']['Items']['Item'].nil?

      output['amazon'] ||= []

      # did we get a single track or an array back?
      if song_file['ItemSearchResponse']['Items']['Item'].kind_of?(Array)

        song_file['ItemSearchResponse']['Items']['Item'].each do |song|

          puts song['ItemAttributes']['Title'].downcase.gsub(/[^a-z ]/, '').gsub(/ /, '-') + " vs. " + results['track']['name'].downcase.gsub(/[^a-z ]/, '').gsub(/ /, '-')

          if song['ItemAttributes']['Title'].downcase.gsub(/[^a-z ]/, '').gsub(/ /, '-') == results['track']['name'].downcase.gsub(/[^a-z ]/, '').gsub(/ /, '-')
            # we found a good match so save it.
            output['amazon'] << song
            break
          end

        end #end of loop

        if output['amazon'].length == 0
          output['amazon'] << song_file['ItemSearchResponse']['Items']['Item'].first
        end

      #we've just got one:
      else
        output['amazon'] << song_file['ItemSearchResponse']['Items']['Item']
      end

    #not found on amazon...
    else

      output['error'] = "not found by amazon #{results['track']['name'] }"

      playlist.add_to_set(:tracks, output)
      playlist.save
      puts "AMAZON ERROR"

      return

    end

    playlist.add_to_set(:tracks, output)
    playlist.save
    puts "DONE saving"


  end
end