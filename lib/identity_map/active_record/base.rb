module ActiveRecord # :nodoc:
  class Base # :nodoc:
    module IdentityMap # :nodoc:
      module ClassMethods
        private
          # Prepares model for work with identity map. 
          # If you want to turn on identity map for certain classes (recomended)
          # you should do like this:
          #
          #   class Address
          #     use_id_map
          #   end
          #
          # If you want to turn on identity map for all ActiveRecord models (not recomended)
          # you should put in some initializator:
          #
          #   class ActiveRecord::Base
          #     use_id_map
          #   end
          def use_id_map() # :doc:
            unless is_a? IdMapClassMethods
              extend IdMapClassMethods
              include IdMapInstanceMethods
              class << self
                alias_method_chain :find, :identity_map
                alias_method_chain :instantiate, :identity_map
              end
              alias_method_chain :create, :identity_map
              alias_method_chain :destroy, :identity_map
            end
          end
      end
      
      # :enddoc:
      module IdMapClassMethods

        def id_map
          thread_id_map.try(:for_class, self)
        end
        
        def if_id_map
          map = id_map
          yield map if map
        end
        
        private
        
          def fetch_single(map, id)
            if (obj = map[id]) && obj.attribute_names == column_names
              obj
            end
          end
        
          def fetch_from_map(map, ids)
            result, not_cached = [], []
            ids.each do |id|
              if ( obj = fetch_single(map, id) )
                result << obj
              else
                not_cached << id
              end
            end
            unless not_cached.empty?
              add = yield not_cached
              result.concat( add ) if add
            end
            result
          end
      
          def find_with_identity_map( *args )
            if_id_map do |map|
              from_arg0 = args.size == 1 ||
                    args[1].is_a?(Hash) && !args[1].values.any?
              from_condition_ids = !from_arg0 &&
                    (args[0] == :all || args[0] == :first) &&
                    args.size == 2 && args[1].is_a?(Hash) &&
                    args[1].all?{|key, value| key == :conditions || value.blank?} &&
                    args[1][:conditions].is_a?(Hash) &&
                    args[1][:conditions].keys == [:id]
              if from_arg0 || from_condition_ids
                ids = from_arg0 ? args[0] : args[1][:conditions][:id]
                if ids.is_a?(Array)
                  if from_arg0
                    fetch_from_map( map, ids, &method(:find_without_identity_map) )
                  elsif args[0] == :all
                    fetch_from_map( map, ids ){|not_cached| 
                        find_without_identity_map(:all, {:conditions=>{:id=>not_cached}})
                    }
                  elsif args[0] == :first
                    to_find = nil
                    result = fetch_from_map( map, ids ){|not_cached| to_find = not_cached; nil}
                    unless result.empty?
                      result.first
                    else
                      find_without_identity_map(:first, {:conditions=>{:id=>to_find}})
                    end
                  end
                else
                  fetch_single(map, ids)
                end
              end
            end || find_without_identity_map(*args)
          end
          
          def instantiate_with_identity_map( record )
            if_id_map do |map|
              id = record[primary_key]
              if (object = map[id])
                attrs = object.instance_variable_get( :@attributes )
                unless (changed = object.instance_variable_get( :@changed_attributes )).blank?
                  for key, value in record
                    if changed.has_key? key
                      changed[key] = value
                    else
                      attrs[key] = value
                    end
                  end
                else
                  attrs.merge!( record ) unless attrs == record
                end
                object
              else
                map[id] = instantiate_without_identity_map( record )
              end
            end || instantiate_without_identity_map( record )
          end
          
          def delete_with_identity_map( ids )
            res = delete_without_identity_map( ids )
            if_id_map{|map| [ *ids ].each{|id| map.delete(id) } }
            res
          end
      end
      
      module IdMapInstanceMethods
        private
          def create_with_identity_map
            id = create_without_identity_map
            self.class.if_id_map{|map| map[id] = self }
            id
          end
          
          def destroy_with_identity_map
            res = destroy_without_identity_map
            self.class.if_id_map{|map| map.delete(id) }
            res
          end
      end
    end
    
    extend IdentityMap::ClassMethods
  end
end

