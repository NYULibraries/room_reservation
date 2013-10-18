class RoomsController < ApplicationController
  authorize_resource
  respond_to :html, :js
  
  # GET /rooms
  def index
    options = params.merge({ :direction => (params[:direction] || 'asc'), :sort => (params[:sort] || sort_column.to_sym), :page => (params[:page] || 1), :per => (params[:per] || 20) })
    # Get Rooms from ElasticSearch through tire DSL
    @rooms = Room.tire.search do
      query { string options[:q] } unless options[:q].blank?
      sort { by options[:sort], options[:direction] }
      page = options[:page].to_i
      search_size = options[:per].to_i
      from (page -1) * search_size
      size search_size
    end
    respond_with(@rooms)
  end

  # GET /rooms/1
  def show
    @room = Room.find(params[:id])
    respond_with(@room)
  end

  # GET /rooms/new
  def new
    @room = Room.new
    respond_with(@room)
  end

  # GET /rooms/1/edit
  def edit
    @room = Room.find(params[:id])
    respond_with(@room)
  end

  # POST /rooms
  def create
    @room = Room.new(params[:room])   
    @room.hours = hours_hash

    flash[:notice] = t("rooms.create.success") if @room.save
    respond_with(@room)
  end

  # PUT /rooms/1
  def update
    @room = Room.find(params[:id])
    @room.hours = hours_hash
     
    flash[:notice] = t("rooms.update.success") if @room.update_attributes(params[:room])
    respond_with(@room)
  end

  # DELETE /rooms/1
  def destroy
    @room = Room.find(params[:id])
    @room.destroy
    
    respond_with(@room)
  end
  
  # GET /rooms/sort
  def index_sort
    @rooms = Room.reorder(sort_column.to_sym)

    respond_with(@rooms)
  end

  # PUT /rooms/sort  
  def update_sort
    @rooms = Room.reorder(sort_column.to_sym)
    
    # Have to iterate through each room in order to reindex sort order
    # Could be a scalability issue moving forward
    params[:rooms].each_with_index do |id, index|
      room = Room.find(id)
      room.sort_order = index+1
      room.save
    end 

    flash[:notice] = t("rooms.update_sort.success")

    respond_with(@rooms, :location => sort_rooms_url)
  end
  
  # Implement sort column function for this model
  def sort_column
    super "Room", "sort_order"
  end
  helper_method :sort_column
  
private

  # Convert hours parameter to a hash
  def hours_hash
    @hours_hash ||= { 
      :hours_start => {
        :hour => params[:hours_start][:hour],
        :minute => params[:hours_start][:minute],
        :ampm => params[:hours_start][:ampm]
      }, 
      :hours_end => {
        :hour => params[:hours_end][:hour],
        :minute => params[:hours_end][:minute],
        :ampm => params[:hours_end][:ampm]
      } 
    }
  end
  
end
