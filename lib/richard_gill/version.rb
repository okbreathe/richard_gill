module RichardGill
  module Version
    def self.extended(base)
      base.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        include ::DataMapper::Resource unless ancestors.include?(::DataMapper::Resource)

        property :id,               Serial unless properties.named?(:id)
        property :data,             Yaml
        property :number,           Integer
        property :versionable_id,   Integer
        property :versionable_type, String

        timestamps :created_at
        
        include InstanceMethods
        extend ClassMethods

        alias :changeset :data

      RUBY
    end # self.extended

    module ClassMethods

      def is_scoped?
        !!@_is_scoped
      end

      # ==== Returns
      # Foreign Key
      def scope_key
        @_scope_key
      end

      # ==== Returns
      # Model
      def scoped_on
        @_scoped_on
      end

      def for(obj, opts={})
        all({
          :versionable_id   => obj.id, 
          :versionable_type => obj.class
        }.merge(opts))
      end

      def latest(opts={})
        all({:limit => 20, :order => [:created_at.desc] }.merge(opts))
      end

    end # ClassMethods

    module InstanceMethods
      def initial?
        number == 0
      end

      def object
        (@object_model ||= ::Object.full_const_get(versionable_type)).get(versionable_id)
      end
    end # InstanceMethods
  end
end # RichardGill
