class UsersController < ApplicationController
  def index
    @user = current_user
  end

  def new
    puts 'here'
    @user = User.new
  end

  def me
    @user = current_user
    render 'show'
  end

  def show
    @user = User.find_by_username(params[:id])
  end

  def edit
    @user = current_user
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_url, :notice => 'Signed up!'
    else
      render 'new'
    end
  end

  def recipes
    @user = User.find_by_username(params[:id])
    @recipes = @user.recipes
  end

end
