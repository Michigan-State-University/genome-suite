class ReSeq < Experiment
  has_one :reads_track, :foreign_key => "experiment_id", :dependent => :destroy
  has_one :bam, :foreign_key => "experiment_id"
  has_one :big_wig, :foreign_key => "experiment_id"
  
  def asset_types
    {"Bam" => "Bam","BigWig" => "BigWig"}
  end
  
  # overrides load to include big_wig generation
  def load_asset_data
    return false unless super
    begin
      if(bam && !big_wig)
        self.create_big_wig(:data => bam.create_big_wig)
        big_wig.load if big_wig
      end
      return true
    rescue
      return false
    end
  end
  
  # TODO: Merge variant track / exp with re_seq
  def create_tracks
    create_reads_track(:assembly => assembly) unless reads_track
  end
  
  def summary_data(start,stop,num,chrom)
    (self.big_wig ? big_wig.summary_data(start,stop,num,chrom).map(&:to_f) : [])
    
  end
  
  def get_reads(start, stop, chrom)
    bam.get_reads(start, stop, chrom)
  end
  
  def get_reads_text(start, stop, chrom,opts)
    bam.get_reads_text(start, stop, chrom,opts)
  end
  
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
  
  def asset_types
    {"Bam" => "Bam"}
  end
  
  ##Track Config
  def iconCls
    "blocks"
  end

  def single
    self.show_negative == "false" ? "true" : "false"
  end
  
  def find_read(read_id, chrom, pos)
    bam.find_read(read_id, chrom, pos)
  end
  
end