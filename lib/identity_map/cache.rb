module ActiveRecord # :nodoc:
  class Base # :nodoc:
    module ThreadIdentityMap # :nodoc:
      # ClassIdMap do the job of properly use typecasted +id+ value of model object
      # for search in a cache
      class ClassIdMap
        def initialize(klass)
          @objects = {}
          @object = klass.allocate
          @object.instance_variable_set(:@attributes, {:id=>nil})
          @object.instance_variable_set(:@attributes_cache, {})
        end
        
        def [](id)
          @object.id = id
          @objects[@object.id]
        end
        
        def []=(id, v)
          @object.id = id
          @objects[@object.id] = v
        end
        
        def delete(id)
          @object.id = id
          @objects.delete(@object.id)
        end
      end
      
      # Manages separated object caches for each model
      class IdMap
      
        def initialize
          @objects = {}
        end
      
        def for_class(klass)
          @objects[ klass.base_class ] ||= ClassIdMap.new(klass)
        end
        
      end
      
      module ClassMethods
        # Creates new identity map and put it in thread local storage
        #
        # For most use cases +with_id_map+ should be used instead.
        #
        # Usage:
        #   ActiveRecord::Base.create_identity_map
        def create_identity_map
          set_thread_id_map IdMap.new
        end
        
        # Remove identity map from thread local storage
        #
        # For most use cases +without_id_map+ should be used instead.
        #
        # Usage:
        #   ActiveRecord::Base.drop_identity_map
        def drop_identity_map
          set_thread_id_map nil
        end
        
        # Execute block with identity map.
        #
        # If it called with +true+, then new instance of identity map would be used
        # regardless of any present.
        #
        # If it called with +false+, then it only ensures that identity map created if absent.
        #
        # Default is +true+
        #
        # Usage:
        #   ActiveRecord::Base.with_id_map do
        #     #do_some_actions
        #   end
        def with_id_map( fresh = true)
          old = thread_id_map
          create_identity_map if fresh || old.nil?
          yield
        ensure
          set_thread_id_map old
        end
        
        # Execute block with identity map turned off.
        #
        # Usage:
        #   ActiveRecord::Base.without_id_map do
        #     #do_some_actions
        #   end
        def without_id_map
          old = thread_id_map
          drop_identity_map
          yield
        ensure
          set_thread_id_map old
        end
        
        protected
        
          def thread_id_map
            Thread.current[:ar_identity_map]
          end
          
          def thread_id_map=(v)
            Thread.current[:ar_identity_map] = v
          end
          
          alias set_thread_id_map thread_id_map=
        
      end
    end
    
    extend ThreadIdentityMap::ClassMethods
  end
end
