class Ingredient < ActiveRecord::Base
  has_many :amounts
  has_many :recipes, :through => :amounts
  #has_and_belongs_to_many :recipes

  def to_param
    name.parameterize
  end
end
