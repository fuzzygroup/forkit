 class RecipesController < ApplicationController
  # GET /recipes
  # GET /recipes.json
  def index
    @recipes = Recipe.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @recipes }
    end
  end

  # GET /recipes/1
  # GET /recipes/1.json
  def show
    name = params[:id].gsub("-", "\s")
    @recipe = Recipe.find_by_name(name)
    @recipe = Recipe.find(params[:id]) if @recipe.nil?
    puts @recipe.ingredients.inspect
    puts @recipe.amounts.inspect
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @recipe }
    end
  end

  # GET /recipes/new
  # GET /recipes/new.json
  def new
    @recipe = Recipe.new
    @availableIngredients = Ingredient.all
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @recipe }
    end
  end

  # GET /recipes/1/edit
  def edit
    name = params[:id].gsub("-", "\s")
    @recipe = Recipe.find_by_name(name)
    @recipe = Recipe.find(params[:id]) if @recipe.nil?
  end

  # POST /recipes
  # POST /recipes.json
  def create
    @recipe = Recipe.new(params[:recipe])
    @ingredients = params[:ingredients]
    @ingredients.each do |i|
      if i.empty?
        break
      end
      i = i.gsub(/\b\w/){$&.upcase}
      ingredient = Ingredient.find_by_name(i)
      if ingredient.nil?
        ingredient = Ingredient.new({"name" => i})
      end
      @recipe.ingredients << ingredient
    end
    @recipe.users << current_user
    
    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
        format.json { render json: @recipe, status: :created, location: @recipe }
      else
        format.html { render action: "new" }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /recipes/1
  # PUT /recipes/1.json
  def update
    name = params[:id].gsub("-", "\s")
    @recipe = Recipe.find_by_name(name)
    @recipe = Recipe.find(params[:id]) if @recipe.nil?
    respond_to do |format|
      if @recipe.update_attributes(params[:recipe])
        format.html { redirect_to @recipe, notice: 'Recipe was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1
  # DELETE /recipes/1.json
  def destroy
    name = params[:id].gsub("-", "\s")
    @recipe = Recipe.find_by_name(name)
    @recipe = Recipe.find(params[:id]) if @recipe.nil?
    @recipe.destroy

    respond_to do |format|
      format.html { redirect_to recipes_url }
      format.json { head :no_content }
    end
  end

end
