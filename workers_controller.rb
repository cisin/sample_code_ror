class WorkersController < ApplicationController

  before_filter :authenticate_worker!, :except => [:show, :public]
  before_filter :authenticate_employer!, :only => :show

  def my_account
    #Show my full profile
    @user = current_user
    calendar_gon_variables(@user)
    render :action => :show
  end

  def show
    #Show full profile (must be employer)
    @user = Worker.find_by_id(params[:id])
    calendar_gon_variables(@user)
  
  end
  
  def public
    @user = Worker.allow_public.find_by_id(params[:id])
    if @user
      calendar_gon_variables(@user)
      #use params[:action] == "public" to delemit what can be seen
      #or simply employer_signed_in? 
      render :action => :show
    else
      redirect_to :back
      flash[:error] = t('flash.error.user_not_exists')
    end
  end

  def edit
    @user = current_user
  end

  def update
    #binding.pry
    @user = current_user
    @user.set_default_date(params[:worker])
    if @user.update_attributes(params[:worker])
      flash[:notice] = t('flash.message.account_updated')
      redirect_to my_account_path
    else
      @show_all = true unless params[:part].present? 
      render :action => (params[:account] ? :my_account : :edit)
    end
  end

  def update_account
    @user = current_user
    if @user.update_attributes(params[:worker])
      flash[:notice] = t('flash.message.account_updated')
      redirect_to my_account_path
    else
      render "workers/registrations/edit"
    end
  end


end

