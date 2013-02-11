class Playlist < ActiveRecord::Base
  include Mongoid::Document
  attr_accessible :name
 
  field :input_string, type: String
  field :status, type: String, default: ->{'DRAFT'}
  field :tracks, type: Array, default: ->{Array.new}
  field :num_tracks, type: Integer #this stores the number of EXPECTED tracks to confirm when things are done.
end
