class SyntheticsController < ApplicationController
  ##Ajax Route
  def sample_select
    assembly = Assembly.find(params[:assembly_id])
    render :partial => 'sample_select', :locals => {:samples => assembly.samples, :synthetic => Synthetic.new}
  end
  
  ##restful routes
  def index
    query = (params[:query] || '').upcase
    @synthetics = Synthetic.accessible_by(current_ability).includes(:assembly => [:species => :scientific_name]).where{upper(name) =~ "%#{query}%"}.order("taxon_name.name ASC")
    @species = @synthetics.map(&:assembly).map(&:species).uniq
  end

  def show
    @synthetic = Synthetic.find(params[:id]) 
  end

  def new
    @assemblies = Assembly.includes(:taxon => :scientific_name).order("taxon_name.name")
    @synthetic = Synthetic.new
  end

  def create
    #convert sample ids to new components
    params[:synthetic][:a_components] = params[:a_samples].collect!{|sample_id| AComponent.new(:sample_id => sample_id)} unless params[:a_samples].blank?
    params[:synthetic][:b_components] = params[:b_samples].collect!{|sample_id| BComponent.new(:sample_id => sample_id)} unless params[:b_samples].blank?
    
    ActiveRecord::Base.transaction do
      @synthetic = Synthetic.new(params[:synthetic])
      @synthetic.user = current_user
      if(@synthetic.valid?)
        @synthetic.save
        flash[:notice]="New Synthetic Sample Created Successfully"
        redirect_to :action => :show
      else
        @assemblies = Assembly.includes(:species => :scientific_name).order("taxon_name.name")
        render :action => :new
      end
    end
  end

  def edit
    @synthetic = Synthetic.find(params[:id])
    @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
  end

  def update
    begin
      @synthetic = Synthetic.find(params[:id])
      #convert sample ids to new components
      params[:synthetic][:a_components] = params[:a_samples].collect!{|sample_id| AComponent.new(:sample_id => sample_id)} unless params[:a_samples].blank?
      params[:synthetic][:b_components] = params[:b_samples].collect!{|sample_id| BComponent.new(:sample_id => sample_id)} unless params[:b_samples].blank?
      
      ActiveRecord::Base.transaction do
        @synthetic.update_attributes(params[:synthetic])
        if @synthetic.errors.empty?

          # #remove old components from synthetic and add new ones
          # @synthetic.components.destroy_all
          # @synthetic.a_components = params[:a_samples].collect{|sample_id| AComponent.create(:sample_id => sample_id)}
          # @synthetic.b_components = params[:b_samples].collect{|sample_id| BComponent.create(:sample_id => sample_id)}

          #doublecheck
          # raise ActiveRecord::RecordInvalid if (@synthetic.a_components.empty? || @synthetic.b_components.empty?)

          flash[:notice]="Synthetic Sample #{@synthetic.name} Updated"
          redirect_to :action => :show
        else

          #reset instance variables
          # @samples = @synthetic.bioentry.samples
          @assemblies = Assembly.includes(:taxon => :scientific_name).order('taxon_name.name asc')
          render :action => :edit
        end
      end        
    rescue => e
      flash[:error]="Error updating sample."
      server_error(e,"Error")
      redirect_to :action => :index
    end
  end

  def destroy
    @synthetic = Synthetic.find(params[:id])
    name = @synthetic.name
    @synthetic.destroy
    flash[:notice]="Synthetic Sample #{name} Removed"
    redirect_to :action => :index
  end


end