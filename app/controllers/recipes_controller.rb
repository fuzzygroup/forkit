 class RecipesController < ApplicationController
  layout 'recipes'
  helper_method :sort_type, :sort_direction
  # GET /recipes
  # GET /recipes.json
  def index
    @recipes = Recipe.order(sort_type + " " + sort_direction).page(params[:page]).per(9)
    respond_to do |format|
      format.html { render :layout => 'wall'}
      format.json { render json: @recipes }
      format.js
    end
  end

  # GET /recipes/1
  # GET /recipes/1.json
  def show
    @page = true
    @recipe = Recipe.find_by_url_slug(params[:id])
    @ingredients = @recipe.ingredients
    if @recipe.nil?
      @recipe = Recipe.find_by_url_slug(params[:name])
    end
    @created_by = name_to_use(User.find(@recipe.created_by))

    if current_user
      if current_user.personalRecipeInfo.find_by_recipe_id(@recipe.id).favorite == true
        @favorite = true
      else
        @favorite = false
      end
      @personal_rating = current_user.personalRecipeInfo.where("recipe_id=#{@recipe.id}").first
      if @personal_rating.nil?
        @personal_rating = nil
      else
        @personal_rating = @personal_rating.rating
      end
      if session[:recent_recipes].index(@recipe.id) == nil
        if session[:recent_recipes].count > 3
          session[:recent_recipes].shift
        end
        session[:recent_recipes].push(@recipe.id)
        logger.debug session[:recent_recipes]
      end
    end
    
    @users = @recipe.users
    @forks = @recipe.favorites
    #is this my recipe?
    @myRecipe = true if @recipe.users.first == current_user

    respond_to do |format|
      format.html
      format.json { render json: @recipe }
      format.js
    end
  end

  def search
    @recipes = Recipe.order('name ASC')
    render :action => 'show'
  end

  # GET /recipes/new
  # GET /recipes/new.json
  def new
    @recipe = Recipe.new
    @recipe.ingredients.build
    @availableIngredients = Ingredient.order('name ASC')
    respond_to do |format|
      if current_user
        format.html # new.html.erb
        format.json { render json: @recipe }
      else
        format.html { redirect_to recipes_url, notice: 'You must be logged in to create a recipe!'}
      end
    end
  end

  # GET /recipes/1/edit
  def edit
    @recipe = Recipe.find_by_url_slug(params[:id])
    @recipe.ingredients.build
    #@ingredients = @recipe.ingredients
    @availableIngredients = Ingredient.order('name ASC')
  end

  # POST /recipes
  # POST /recipes.json
  def create
    params[:recipe]['url_slug'] = get_slug(params[:recipe]['name'])
    params[:recipe]['created_by'] = current_user.id
    @recipe = Recipe.new(params[:recipe])

    #old ingredient save, keep for reference
=begin
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
    end
=end
    @recipe.users << current_user
    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
        format.json { render json: @recipe, status: :created, location: @recipe }
      else
        format.html { render action: 'new' }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /recipes/1
  # PUT /recipes/1.json
  def update
    @recipe = Recipe.find_by_url_slug(params[:id])
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
      if !@recipe.ingredients.include?(ingredient)
        @recipe.ingredients << ingredient
      end
    end
    params[:recipe]['url_slug'] = get_slug(params[:recipe]['name'])
    #params[:recipe]['desc'] = '<p>'+params[:recipe]['desc'].gsub(/(\r\n)+/, '</p><p>') + '</p>'
    respond_to do |format|
      if @recipe.update_attributes(params[:recipe])
        format.html { redirect_to @recipe }
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
    @recipes = Recipe.all
    respond_to do |format|
      format.html {redirect_to recipes_url, :status => 401}
      format.json {redirect_to recipes_url, :status => 401}
    end
  end

  # POST /recipes/:id/update_rating
  def update_rating
    @recipe = Recipe.find_by_url_slug(params[:id])
    @personal_rating = current_user.personalRecipeInfo.where("recipe_id=#{@recipe.id}").first
    if @personal_rating.nil?
      @recipe.users << current_user
      if @recipe.save
        #do nothing
      else
        redirect_to recipes_url, :notice => 'Something went wrong.'
      end
    end
    @personal_rating.rating = Integer(params[:rating])
    respond_to do |format|
      if @personal_rating.save
        @recipe.rating = @recipe.personalRecipeInfo.average(:rating)
        @recipe.total_ratings = @recipe.personalRecipeInfo.where("rating IS NOT NULL").count
        if @recipe.save
          format.json {render json: @recipe}
          format.xml {render xml: @recipe}
        else
          format.json {render json: @recipe.errors, status: :unprocessable_entity}
          format.xml {render xml: @recipe.errors}
        end
      else
        format.json {render json: @recipe.errors, status: :unprocessable_entity}
        format.xml {render xml: @recipe.errors}
      end
    end
  end

  def favorite
    recipe = Recipe.find_by_url_slug(params[:recipe_id])
    user = current_user
    render :json => recipe
  end

  def render_ingredients_input
    respond_to do |format|
      format.js {render 'index.js'}
    end
  end

  def get_url_format(slug)
    return slug.gsub(/\s/, '-')
  end

  def get_slug(name)
    return name.downcase.gsub(/\s/,'-')
  end

  private

  def sort_type
    Recipe.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def nameToUse(user)
  if user.display_name
    return [user.display_name, user.display_name]
  elsif user.name
    return [user.name, user.name.split(' ')[0]]
  else
    return [user.email, user.email]
  end
end

end
