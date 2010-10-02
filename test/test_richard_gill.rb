require 'helper'
require 'data'

class TestRichardGill < Test::Unit::TestCase

  context "Objects using RichardGill" do
    setup do
      new_user
    end

    should "be watched" do
      assert !Unwatched.is_richard_gill_watching?
      assert Article.is_richard_gill_watching?
    end

    should "create an Version model" do
      assert_equal "constant", defined?(Version)
    end

    should "know its own version model" do
      assert_equal Version, Article.version_model
    end

    should "return an empty array for an objects versions" do
      assert_equal [], Article.new(:title => "article", :user => new_user).versions
    end

    context "a scoped model" do

      setup do
        @rifle = Rifle.create(:name => "gun")
        @rifle.update(:name => "biggergun")
        @ammo = Ammo.create(:name => "ammo", :rifle => @rifle)
        @ammo.update(:name => "superammo")
      end

      should "allow you to scope the versioning model" do
        assert ScopedVersion.is_scoped?
        assert_not_nil ScopedVersion.properties[:rifle_id]
      end

      should "add relationships" do
        assert_not_nil Rifle.relationships[:scoped_versions]
        assert_not_nil ScopedVersion.relationships[:rifle]
      end

      should "record the scope (fk) when writing a version" do
        @ammo.versions.each do |v|
          assert_not_nil v.rifle_id
        end
      end

      should "allow objects to return scoped_versions" do
        assert @rifle.scoped_versions.any?
        @rifle.scoped_versions.each do |v|
          assert_equal @rifle.id, v.rifle_id
        end
      end

      should "record versions even when a object is not in the given scope" do
        assert @rifle.versions.any?
        @rifle.versions.each do |v|
          assert_nil v.rifle_id
        end
      end

      teardown do
        Rifle.all.destroy
        Ammo.all.destroy
      end

    end

    context "versioning" do

      setup do
        new_article
        @article.update(:title => "changed")
        @article.update(:title => "changed1")
        @article.update(:body  => "body")
      end

      should "record changes as new versions" do
        assert Version.all.length == 4
        assert @article.versions.length == 3
      end

      should "changeset should be hashes with [old_value,new_value]" do
        versions = @article.versions
        assert_equal({:title => ["article", "changed" ]}, versions[2].data)
        assert_equal({:title => ["changed", "changed1"]}, versions[1].data)
        assert_equal({:body =>  [nil, "body"]}, versions[0].data)
      end

      should "increment the version number" do
        assert Version.all.last.number = 2
      end

      should "return the user responsible for the change" do
        assert_equal new_user, @article.previous_version.user
      end

      should "return the object that is the source of the change" do
        assert_equal @article, Version.last.object
      end

      should "destroy versions of the object if it is destroyed" do
        @article.destroy
        assert_equal 0, Version.all.length
      end

      should "never version created_{at|on} or updated_{at|on}" do
        [:created_at, :created_on, :updated_at, :updated_on].each do |attr|
          assert_nil @article.previous_version.changeset[attr]
        end
      end

      teardown do
        ::Article.all.destroy!
      end

    end

    context "when properties are not dirty" do

      setup do
        new_article(:title => "article", :number => 1 )
        @article.update(:title => "article", :number => 1)
        @article.update(:title => "article", :number => "1")
      end

      should "not create versions" do
        assert Version.all.length == 1
        assert @article.versions.length == 0
      end

      teardown do
        ::Article.all.destroy!
      end
    end

    context "dependent relationships" do
      setup do
        @pig = Pig.create :name => "piggins", :babies => ([1,2,3].map {|n| Baby.new(:name => n)})
        @pig.update(:name => "tubbs") 
        @pig.babies.each {|b| b.update(:name => b.name + "_")}
      end

      should "destroy child versions" do
        assert_equal 8, Version.all.length
        @pig.destroy
        assert_equal 0, Version.all.length
      end

      teardown do
        ::Pig.all.destroy!
        ::Baby.all.destroy!
      end
    end

    context "given an :+except+ clause" do
      setup do
        @student = Student.create
      end
      should "ignore properties specified by :+except+" do
        @student.update(:name => "ignored", :is_werewolf => true)
        assert_equal({ :is_werewolf => [false,true] }, @student.previous_version.changeset)
      end

      should "not create new versions if there are no changes in non-ignored properties" do
        @student.update(:name => "ignored", :age => 20)
        assert_equal 1, Version.all.length 
      end

      teardown do
        ::Student.all.destroy!
      end
    end

    context "given an :+only+ clause" do
      setup do
        @camper = Camper.create
      end

      should "only include properties specified by :+only+" do
        @camper.update(:is_werewolf => true, :age => 20)
        assert_equal({ :age => [5,20] }, @camper.previous_version.changeset)
      end

      should "not create new versions if there are changes in ignored properties" do
        @camper.update(:is_werewolf => true)
        assert_equal 1, Version.all.length 
      end

      teardown do
        ::Camper.all.destroy!
      end
    end

    context "Conditional Versions" do
      setup do
        @pig = Pig.create(:name => "success")
      end

      context "given an :+if+ condition" do
        setup do
          Pig.is :watched, :if => lambda { |obj| obj.name =~ /success/ }
        end

        should "create a version if the proc given by :+if+ returns true" do
          @should_create = true
          @pig.update(:name => "success_")
          assert_equal 1, @pig.versions.length
          assert_equal 2, Version.all.length
        end

        should "not create a version if the proc given by :+if+ returns false" do
          @pig.update(:name => "fail")
          assert_equal 0, @pig.versions.length
          assert_equal 1, Version.all.length
        end

      end

      context "given an :+unless+ condition" do
        setup do
          Pig.is :watched, :unless => lambda { |obj| obj.name =~ /fail/ }
        end

        should "create a version if the proc given by :+unless+ returns false" do
          @pig.update(:name => "success_")
          assert_equal 1, @pig.versions.length
          assert_equal 2, Version.all.length
        end

        should "not create a version if the proc given by :+unless+ returns true" do
          @pig.update(:name => "fail")
          assert_equal 0, @pig.versions.length
          assert_equal 1, Version.all.length
        end

      end

      teardown do
        ::Pig.all.destroy!
      end
    end

    context "Reverting" do
      setup do
        @pig = Pig.create(:name => "first")
        @pig.update(:name => 'second')
        @pig.update(:name => 'third')
        @pig.update(:name => 'fourth')
      end

      should "revert back one version without arguments" do
        @pig.reload
        @pig.revert
        assert_equal "third", @pig.name
      end

      should "be able revert a specified number of version" do
        @pig.revert(2)
        assert_equal "second", @pig.name
        @pig.revert(3)
        assert_equal "first", @pig.name
      end

      teardown do
        ::Pig.all.destroy!
      end
    end

    teardown do
      ::Version.all.destroy!
    end

  end

end
