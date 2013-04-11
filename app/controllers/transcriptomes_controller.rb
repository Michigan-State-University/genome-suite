class TranscriptomesController < ApplicationController
  def index
     @species = Taxon.with_species_transcriptomes.accessible_by(current_ability).order "taxon_name.name ASC"
     @biodatabase = Bio::Biodatabase.find_by_biodatabase_id(params[:biodatabase_id])||Bio::Biodatabase.first
  end
end