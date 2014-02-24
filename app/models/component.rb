# == Schema Information
#
# Table name: components
#
#  created_at              :datetime
#  sample_id           :integer
#  id                      :integer          not null, primary key
#  synthetic_sample_id :integer
#  type                    :string(255)
#  updated_at              :datetime
#

class Component < ActiveRecord::Base
   validates_uniqueness_of :sample_id, :scope => [:synthetic_sample_id]
   belongs_to :synthetic_sample, :class_name => "Sample", :foreign_key => :synthetic_sample_id
   belongs_to :sample
end
