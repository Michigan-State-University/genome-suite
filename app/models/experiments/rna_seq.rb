# == Schema Information
#
# Table name: experiments
#
#  a_op               :string(255)
#  assembly_id        :integer
#  b_op               :string(255)
#  concordance_set_id :integer
#  created_at         :datetime
#  description        :string(2000)
#  file_name          :string(255)
#  group_id           :integer
#  id                 :integer          not null, primary key
#  mid_op             :string(255)
#  name               :string(255)
#  sequence_name      :string(255)
#  show_negative      :string(255)
#  state              :string(255)
#  total_count        :integer
#  type               :string(255)
#  updated_at         :datetime
#  user_id            :integer
#

class RnaSeq < Experiment
  has_one :reads_track, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :histogram_track, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :feature_counts, :foreign_key => "experiment_id", :dependent => :delete_all
  has_one :bam, :foreign_key => "experiment_id"
  has_one :big_wig, :foreign_key => "experiment_id"
  smoothable
  
  def asset_types
    {"Bam" => "Bam","BigWig" => "BigWig"}
  end
  # overrides load to include big_wig generation
  def load_asset_data
    return false unless super
    begin
      self.update_attribute(:total_count, total_mapped_reads)
      if(bam && !big_wig)
        self.create_big_wig(:data => bam.create_big_wig)
        big_wig.load if big_wig
      end
      return true
    rescue => e
      puts e
      return false
    end
  end
  
  # generates tracks depending on availabale assets
  # creates ReadsTracks if a bam is present otherwise HistogramTracks are created
  def create_tracks
    if(bam)
      unless reads_track
        create_reads_track(:assembly => assembly)
        # replace the histogram track as soon as we have a bam
        histogram_track.destroy if histogram_track
      end
    else
      # TODO: Test big wig only expression experiments. Need fix for Peaks .. data url etc..
      create_histogram_track(:assembly => assembly) unless histogram_track
    end
  end
  
  # searches for a read by id and returns alignment data. See bam#find_read for details
  def find_read(read_id, chrom, pos)
    bam.find_read(read_id, chrom, pos)
  end
  # returns histogram data see big_wig#summary_data for details
  def summary_data(start,stop,num,chrom)
    (self.big_wig ? big_wig.summary_data(start,stop,num,chrom).map(&:to_f) : [])
  end
  # returns reads in chromosome range see bam#get_reads
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  # returns processed reads as formatted text see bam#get_reads_text
  def get_reads_text(start, stop, chrom,opts)
    bam.get_reads_text(start, stop, chrom,opts)
  end
  # returns the max value stored in the big_wig
  # if a sequence_name is supplied it will return max for that sequence only
  def max(chrom='')
    begin
      if big_wig
        big_wig.max(chrom)
      else
        1
      end
    rescue
      1
    end
  end
  # returns the total count of mapped reads from the bam
  def total_mapped_reads
    bam.try(:total_mapped_reads) || 0
  end
  
  ##Track Config
  def iconCls
    "blocks"
  end

  def single
    self.show_negative == "false" ? "true" : "false"
  end
end
