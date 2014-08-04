require 'lotus/utils/kernel'

module Epiphy
  # An object that is defined by its identity.
  # See Domain Driven Design by Eric Evans.
  #
  # An entity is the core of an application, where the part of the domain
  # logic is implemented. It's a small, cohesive object that express coherent
  # and meaningful behaviors.
  #
  # It deals with one and only one responsibility that is pertinent to the
  # domain of the application, without caring about details such as persistence
  # or validations.
  #
  # This simplicity of design allows developers to focus on behaviors, or
  # message passing if you will, which is the quintessence of Object Oriented
  # Programming.
  #
  # @example With Epiphy::Entity
  #   require 'epiphy/model'
  #
  #   class Person
  #     include Epiphy::Entity
  #     self.attributes = :name, :age
  #   end
  #
  # When a class includes `Epiphy::Entity` the `.attributes=` method is exposed.
  # By then calling the `.attributes=` class method, the following methods are
  # added:
  #
  #   * #id
  #   * #id=
  #   * #initialize(attributes = {})
  #
  # If we expand the code above in pure Ruby, it would be:
  #
  # @example Pure Ruby
  #   class Person
  #     attr_accessor :id, :name, :age
  #
  #     def initialize(attributes = {})
  #       @id, @name, @age = attributes.values_at(:id, :name, :age)
  #     end
  #   end
  #
  # Indeed, **Epiphy::Model** ships `Entity` only for developers's convenience, but the
  # rest of the framework is able to accept any object that implements the interface above.
  #
  # However, we suggest to implement this interface by including `Epiphy::Entity`,
  # in case that future versions of the framework will expand it.
  #
  # @since 0.1.0
  #
  # @see Epiphy::Repository
  module Entity
    # Inject the public API into the hosting class.
    #
    # @since 0.1.0
    #
    # @example With Object
    #   require 'epiphy/model'
    #
    #   class User
    #     include Epiphy::Entity
    #   end
    #
    # @example With Struct
    #   require 'epiphy/model'
    #
    #   User = Struct.new(:id, :name) do
    #     include Epiphy::Entity
    #   end
    def self.included(base)
      base.extend ClassMethods
      base.send :attr_accessor, :id
    end

    module ClassMethods
      # (Re)defines getters, setters and initialization for the given attributes.
      #
      # These attributes can match the database columns, but this isn't a
      # requirement. The mapper used by the relative repository will translate
      # these names automatically.
      #
      # An entity can work with attributes not configured in the mapper, but
      # of course they will be ignored when the entity will be persisted.
      #
      # Please notice that the required `id` attribute is automatically defined
      # and can be omitted in the arguments.
      #
      # @param attributes [Array<Symbol>] a set of arbitrary attribute names
      #
      # @since 0.1.0
      #
      # @see Epiphy::Repository
      # @see Epiphy::Model::Mapper
      #
      # @example
      #   require 'epiphy/model'
      #
      #   class User
      #     include Epiphy::Entity
      #     self.attributes = :name
      #   end
      def attributes=(*attributes)
        @attributes = Lotus::Utils::Kernel.Array(attributes.unshift(:id))

        class_eval %{
          def initialize(attributes = {})
        #{ @attributes.map {|a| "@#{a}" }.join(', ') }, = *attributes.values_at(#{ @attributes.map {|a| ":#{a}"}.join(', ') })
          end
        }

        attr_accessor *@attributes
      end

      def attributes
        @attributes
      end
    end

    # Defines a generic, inefficient initializer, in case that the attributes
    # weren't explicitly defined with `.attributes=`.
    #
    # @param attributes [Hash] a set of attribute names and values
    #
    # @raise NoMethodError in case the given attributes are trying to set unknown
    #   or private methods.
    #
    # @since 0.1.0
    #
    # @see .attributes
    def initialize(attributes = {})
      puts "Passing attrb"
      pp attributes
      puts "End deug"
      attributes.each do |k, v|
        puts "Key class= #{k.class}. value= #{v}"
        case k
          when Symbol
            public_send("#{ k }=", v)
          when String
            puts k
            public_send("#{ k.to_sym }=", v)
        end
      end
    end

    # Overrides the equality Ruby operator
    #
    # Two entities are considered equal if they are instances of the same class
    # and if they have the same #id.
    #
    # @since 0.1.0
    def ==(other)
      self.class == other.class &&
         self.id == other.id
    end 

  end
end

