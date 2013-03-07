class ToolsController < ApplicationController
  def smooth
    @experiments = ChipChip.accessible_by(current_ability).order(:created_at)    
    #create a new smoothed dataset from the supplied experiment.
    if(request.post?)
      begin
        @original=Experiment.find(params[:experiment_id])
        # just to test validity
        @new_experiment = @original.clone({:name => params[:name], :description => params[:description]})
        if(@new_experiment.valid?)
          @original.delay.create_smoothed_experiment( {:name => params[:name], :description => params[:description]}, # pass the exp options again (for use in backgorund job)
            {:window => params[:window].to_i,:type => params[:type],:cutoff => params[:cutoff]}
          )
          flash[:notice] = "The Smoothing Job has been submitted. When it is complete #{params[:name]} will be listed with the other #{@original.class} experiments"
          redirect_to :action => :index
        else
          render :action => "smooth"
        end
      rescue
        logger.info "\n\nError Smoothing dataset: #{$!}\n\n"
        flash[:error] = "Could not create new experiment"
        redirect_to :action => "smooth"
      end
    else      
      #render the form
    end
  end
  
  def details
  end
  
  ## NOTE:
  ## The Variant genes query is deprecated with the switch from Stored Mac to Tabix Variant format
  ##
  # def variant_genes
  #   @assemblies = Assembly.all
  #   @variants, @variant_genes = [],[]
  #   if request.xhr?
  #     if(params[:assembly_id])
  #       @variants = Assembly.find(params[:assembly_id]).variants rescue []
  #     end
  #     render :partial => 'variant_genes_experiments'
  #   elsif params[:assembly_id]
  #     t = Assembly.find(params[:assembly_id]) rescue nil
  #     @variants = t.variants rescue []
  #     if(params[:set_a] && t)
  #       @variant_genes = GeneModel.find_differential_variants(params[:set_a],params[:set_b]||[])
  #       @variant_genes = @variant_genes.where{bioentry_id.in(my{t.bioentries})}
  #       @variant_genes = @variant_genes.includes(:gene,:bioentry)
  #       @variant_genes = @variant_genes.order(:bioentry_id,:start_pos)        
  #     else
  #       flash.now[:error] = "You must select at least 1 experiment from Set A and Set B"
  #     end
  #   else
  #     t = Assembly.first
  #     @variants = t.variants rescue []
  #     params[:assembly_id] = t.id rescue nil
  #   end
  #   respond_to do |format|
  #     format.csv {
  #       csv_out = CSV.generate do |csv|
  #         csv <<  ["Locus Tag","Gene","Start","End","Strand","Sequence"]
  #         @variant_genes.each do |gm|
  #           csv << [ gm.display_name, gm.gene_name, gm.start_pos, gm.end_pos, (gm.strand == 1 ? 'Forward' : 'Reverse'), gm.bioentry.short_name ]
  #         end
  #       end
  #       send_data csv_out, 
  #       :type => 'text/csv; charset=iso-8859-1; header=present', 
  #       :disposition => "attachment; filename=variant_genes_#{Time.now.to_i}.csv"
  #     }
  #     format.html {
  #       unless @variant_genes.empty?
  #         @variant_genes = @variant_genes.paginate(:page => (params[:page] || 1), :per_page => 25)
  #       end
  #     }
  #     if(@variant_genes.empty?)
  #       flash.now[:warning]= "No genes found matching the given criteria. Please expand your search."
  #     end
  #   end
  # end
  
  # GET /tools
  def index
    #@tools = Tool.all
    @jobs = Delayed::Job.find_by_sql("select id, handler, created_at, locked_at, failed_at, handler, last_error from delayed_jobs")
    # index.html.erb
  end
  
  # DELETE /tools/1
  def destroy
    @job = Delayed::Job.find_by_id(params[:id])
    @job.destroy
    respond_to do |wants|
      wants.html { redirect_to(tools_url) }
    end
  end
  # 
  #  # GET /_tools/1
  #  def show
  #  # show.html.erb
  #  end
  # 
  #  # GET /tools/new
  #  def new
  #    @tool = Tool.new
  #  # new.html.erb
  #  end
  # 
  #  # GET /tools/1/edit
  #  def edit
  #  end
  # 
  #  # POST /tools
  #  def create
  #    @tool = Tool.new(params[:tool])
  # 
  #    respond_to do |wants|
  #      if @tool.save
  #        flash[:notice] = 'Tool was successfully created.'
  #        wants.html { redirect_to(@tool) }
  #      else
  #        wants.html { render :action => "new" }
  #      end
  #    end
  #  end
  # 
  #  # PUT /tools/1
  #  def update
  #    respond_to do |wants|
  #      if @tool.update_attributes(params[:tool])
  #        flash[:notice] = 'Tool was successfully updated.'
  #        wants.html { redirect_to(@tool) }
  #      else
  #        wants.html { render :action => "edit" }
  #      end
  #    end
  #  end
  # 

  # 
  #  private
  #    def find_tool
  #      @tool = Tool.find(params[:id])
  #    end
end
