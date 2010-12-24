require "dm-core" 
require "dm-types" 
require "dm-timestamps" 
require "dm-aggregates"
require "active_support/core_ext" 
require "active_support/inflector" 
Dir[File.join(File.dirname(__FILE__), 'richard_gill', '*.rb')].each{|f| require f }

module RichardGill
  
  @@defaults = {
    :version_model => "Version",
    :user_model    => "User",
  }

  def self.extended(base)
    base.class_eval do
      @is_richard_gill_watching = false
    end
  end

  def is_richard_gill_watching?
    @is_richard_gill_watching
  end

  # Fine, fine it's not as funny as I think it is
  alias :is_watched?  :is_richard_gill_watching?
  
  # When the object is updated, a new revision containing the changes is
  # created. 
  # ==== Arguments
  # Options:
  # [:+version_model+] 
  #   The stringified class name of the version model to use
  #   for the association. By default, this is "Version". This model will be
  #   generated if it does not exist. This can vary between models if you choose
  #
  # [:+user_model+] 
  #   The stringified class name of the user model to use
  #   for the association. By default, this is "User". Don't vary this unless you
  #   want things to explode.
  #
  # [:+except+] 
  #   Ignore changes in certain attributes. 
  #   1) Listed attributes will be left out of the change history
  #   2) Only changing the listed attributes will not generate a changeset
  #
  # [:+only+] 
  #   Opposite of [:+except+]
  #
  # [:+if+] 
  #   Whether a new version should be created. 
  #   Takes a proc that will be called with the current object. If the result
  #   of calling the proc is true, then a new version will be created.
  #
  # [:+unless+] 
  #   Same purpose as [:+if+], but creates versions when the proc evaluates to false
  #
  # [:+scope+]
  #   By default ,`obj.versions` will only retrieve the versions for `obj`. If we pass
  #   the scope option, we can add a foreign key to the version model that will allow
  #   us to find all versions within the scope using `object.scoped_versions`.
  #
  #   Let's say that you have three watched models: Forum, Topic and
  #   Comment. 
  #
  #   Forum `has n :topics`. 
  #   Topic `has n :comments`. 
  #
  #   If we wanted to retrieve all the activity associated with a particular forum,
  #   we could scope Topic and Comment to Form:
  #
  #   class Topic
  #     is :watched, :scope => :forum
  #   
  #   class Comment
  #     is :watched, :scope => :forum
  #
  #   This will add a foreign_key column `forum_id` that will be
  #   updated with scoped object's id as the associated objects are updated.  
  #   
  #   NOTE
  #
  #   Unscoped objects will still still use the same versioning
  #   table, however, the foreign_key will obviously be null.
  #
  #   Scoped models must implement a method by the same name as the scope
  #   in order to it to be saved correctly. E.g. Comment, must implement a
  #   `#forum` method
  #
  def is_watched(opts={}, &block)
    @is_richard_gill_watching = true

    class << self
      attr_accessor :richard_gill_options, :version_model, :user_model
    end

    attr_accessor :updated_by

    @richard_gill_options = RichardGill.defaults.merge(opts)

    self.version_model = RichardGill.generate_version_model(@richard_gill_options)
    self.user_model    = RichardGill.user_model(@richard_gill_options)

    if self.user_model.respond_to? :current
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def updated_by; @updated_by || #{self.user_model}.current; end
      RUBY
    end

    extend ClassMethods
    include InstanceMethods

    # TODO This method typecasts the value twice
    versioned_properties.each do |name|
      before :"#{name}=" do |new_value|
        prop = self.class.properties[name]
        prop.lazy_load self if prop.lazy?
        old_value = prop.get self # lazy-loaded properties won't respond to this
        
        unless old_value == prop.typecast(new_value) 
          pending_version_attributes[name] = [old_value,new_value]
        end
      end
    end

    before :create do
      @_just_created = new?
    end

    after :save do
      if ( @_just_created || pending_version_attributes.any? )
        create_version
        pending_version_attributes.clear
        @_just_created = false
      end
    end

    before :destroy do
      destroy_versions
    end

  end

  def self.user_model(opts)
    ::Object.full_const_get(opts[:user_model])
  end

  def self.generate_version_model(opts)
    model_name = opts[:version_model]
    model = 
      if ::Object.const_defined?(model_name)
        ::Object.full_const_get(model_name) 
      else
        ::Object.full_const_set(model_name.camelize, Class.new(::Object) )
      end

    model.extend(RichardGill::Version) unless model.ancestors.include?(RichardGill::Version)
    model.belongs_to opts[:user_model].underscore.to_sym, :model => opts[:user_model]

    if opts[:scope]
      # Article has n, :versions
      (scoped_model = opts[:scope].to_s.classify.constantize).class_eval do
        has n, :scoped_versions, :model => model.to_s, :order => [:created_at.desc]
      end
      model.belongs_to scoped_model.to_s.underscore.to_sym, :required => false
      model.instance_variable_set(:@_is_scoped, true)
      model.instance_variable_set(:@_scope_key, opts[:scope].to_s.foreign_key.to_sym)
      model.instance_variable_set(:@_scoped_on, scoped_model)
    end

    model
  end

  # Setup defaults across all versioned models
  # ==== Arguments
  # Options:
  # [:+version_model+] 
  #   The stringified class name of the version model to use
  #   for the association. By default, this is "Version". This model will be
  #   generated if it does not exist. 
  #
  # [:+user_model+] 
  #   The stringified class name of the user model to use
  #   for the association. 
  #
  def self.setup(opts = {})
    @defaults = @@defaults.merge(opts)
  end

  def self.defaults
    @defaults || @@defaults
  end


  module ClassMethods

    # An array of symbolized names of properties that will be versioned.
    # Note: Timestamp columns are not versioned.
    # @return <Array>
    def versioned_properties
      opts  = richard_gill_options
      props = properties.map(&:name) - [:created_at, :created_on, :updated_at, :updated_on]
      case
        when opts[:only]   then props & opts[:only]
        when opts[:except] then props - opts[:except]
        else props
      end 
    end

  end

  module InstanceMethods

    # Hash of original values to be stored in the
    # versions table when a new version is created. 
    # Cleared after a version record is created.
    # @return <Hash>
    def pending_version_attributes
      @pending_version_attributes ||= {}
    end

    # Iterate through the versions of
    # an object constructing a hash of attributes
    # to replace its current attributes with
    # @return <self>
    def revert(v = 1)
      self.attributes =
        versions(:limit => v).inject({}) do |m,ver|
          next m unless ver.data
          ver.data.each { |k,v| m[k] = v.first } 
          m
        end
      self
    end

    def revert!(v = 1)
      revert(v)
      save
    end

    # Returns a collection of other versions of this resource.
    # The versions are related on the models keys, and ordered
    # by the number property.
    # ==== Note
    # Version.all(...) will always return more results than obj.versions,
    # because obj.versions skips the creation event (number 0), because 
    # it is NOT a version, just a record of creation.
    # @return <Collection>
    def versions(opts = {})
      self.class.version_model.all({          
        :versionable_type => self.class, 
        :versionable_id   => self.id,
        :order       => [:number.desc],
        :number.gt   => 0
      }.merge(opts))
    end

    # @return <Version>
    def previous_version(opts = {})
      versions({:limit => 1}.merge(opts)).first
    end

    protected

    # If the object has the same fk property as the scoped
    # version_model, record it automatically
    def create_version
      return unless should_create_version?
      model    = self.class.version_model
      user_key = self.class.user_model.to_s.underscore.to_sym
      attrs    = {
        :number => model.count(
          :versionable_type => self.class,
          :versionable_id   => self.id
        ),
        user_key     => updated_by,
        :data        => pending_version_attributes,
        :versionable_type => self.class,
        :versionable_id   => self.id
      }

      if model.is_scoped? and self.class.properties[model.scope_key]
        attrs[model.scope_key] = self.send(model.scope_key)
      end

      model.create(attrs)

    end

    # Don't create a version if object doesn't pass
    # callback tests
    def should_create_version?
      opts = self.class.richard_gill_options
      if opts[:if].kind_of?(Proc)
        opts[:if].call(self)     
      elsif opts[:unless].kind_of?(Proc)
        !opts[:unless].call(self) 
      else
        true
      end
    end

    def destroy_versions
      self.class.version_model.all(:versionable_id => self.id, :versionable_type => self.class).destroy!
    end

  end # InstanceMethods

end # RichardGill

DataMapper::Model.append_extensions RichardGill
