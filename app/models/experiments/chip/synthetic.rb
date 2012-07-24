class Synthetic < Experiment
  has_many :histogram_tracks, :foreign_key => "experiment_id", :dependent => :destroy
  has_many :a_components, :foreign_key => :synthetic_experiment_id, :dependent => :destroy
  has_many :b_components, :foreign_key => :synthetic_experiment_id, :dependent => :destroy
  has_many :components, :foreign_key => :synthetic_experiment_id
  validates_presence_of :a_components
  validates_presence_of :b_components
  after_save :set_abs_max
 # has_peaks
  
  ##Specialized methods
  def update_assets
    update_attribute(:state, "ready")
  end
  
  def create_tracks
    create_histogram_track(:bioentry => self.bioentry) if histogram_track.nil?
  end
  
  def display_name
    "( #{a_op}(#{a_components.collect{|c| c.experiment.display_name}.join(", ")}) #{mid_op} #{b_op}(#{b_components.collect{|c| c.experiment.display_name}.join(",")}) )"
  end
  
  def summary_data(num=200)
    a_summaries = []
    a_components.each do |a|
      a_summaries << a.experiment.summary_data(num)
    end    
    b_summaries = []
    b_components.each do |b|
      b_summaries << b.experiment.summary_data(num)
    end
    a_merged = merge_multiple_results(a_op,a_summaries,false)
    b_merged = merge_multiple_results(b_op,b_summaries,false)
    return merge_results(mid_op,a_merged,b_merged,false)
  end
  
  def results_query(start, stop, bases)
    a_results = []
    a_components.each do |a|
      a_results << a.experiment.results_query(start, stop, bases)
    end
    b_results = []
    b_components.each do |b|
      b_results << b.experiment.results_query(start, stop, bases)
    end
    a_merged = merge_multiple_results(a_op,a_results)
    b_merged = merge_multiple_results(b_op,b_results)
    return merge_results(mid_op,a_merged,b_merged)
  end
  
  def base_counts
    bioentry.biosequence.seq.length
  end

  ##Track Config
  def iconCls
    "synthetic_track"
  end
  
  def single
    "false"
  end
  
  ##Class Specific
  def max
    summary_data(1)[0]
  end
  
  def set_abs_max
    # bioentries_experiments
  end
  
  def merge_results(op, a_results, b_results, has_pos = true)
    data = []
    case op
    when "/"
      a_results.each_with_index do |a,idx|
        data << (has_pos ? [a[0],(a[1]/b_results[idx][1])] : (a/b_results[idx]))
      end
    when "-"
      a_results.each_with_index do |a,idx|
        data << (has_pos ? [a[0],(a[1]-b_results[idx][1])] : a-b_results[idx])
      end
    end
    return data
  end

  def merge_multiple_results(op, results, has_pos = true)
    data = []
    comp_count = results.size
    case op
    when "avg"
      results[0].each_with_index do |r, idx|
        avg=0.0
        comp_count.times do |i|
          avg+= (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[idx][0],avg/comp_count] : avg/comp_count)
      end
    when "sum"
      results[0].each_with_index do |r, idx|
        sum=0.0
        comp_count.times do |i|
          sum+= (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[0],sum] : sum)
      end
    when "max"
      results[0].each_with_index do |r, idx|
        vals=[]
        comp_count.times do |i|
          vals<< (has_pos ? results[i][idx][1].to_f : results[i][idx].to_f)
        end
        data<< (has_pos ? [r[idx][0],vals.max] : vals.max)
        end
      end
    return data
  end
   
end


# == Schema Information
#
# Table name: experiments
#
#  id          :integer(38)     not null, primary key
#  bioentry_id :integer(38)
#  user_id     :integer(38)
#  name        :string(255)
#  type        :string(255)
#  description :string(255)
#  file_name   :string(255)
#  a_op        :string(255)
#  b_op        :string(255)
#  mid_op      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  creator_id  :integer(38)
#  updater_id  :integer(38)
#  abs_max     :string(255)
#

