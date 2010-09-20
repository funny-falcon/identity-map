module ActiveRecord
  class Base
    module ThreadIdentityMap
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
      
      class IdMap
      
        def initialize
          @objects = {}
        end
      
        def for_class(klass)
          @objects[ klass.base_class ] ||= ClassIdMap.new(klass)
        end
        
      end
      
      module ClassMethods
        def create_identity_map
          set_thread_id_map IdMap.new
        end
        
        def drop_identity_map
          set_thread_id_map nil
        end
          
        def with_id_map( fresh = true)
          old = thread_id_map
          create_identity_map if fresh || old.nil?
          yield
        ensure
          set_thread_id_map old
        end
        
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
