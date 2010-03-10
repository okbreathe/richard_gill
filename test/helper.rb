require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'rr'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'richard_gill'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  def new_user
    @user = User.first || User.create(:name => "StealthCactus")
  end

  def new_article(opts = {}) 
    opts[:title] ||= "article"
    opts[:user]  ||= new_user
    @article = Article.first(opts) || Article.create(opts)
  end
end
