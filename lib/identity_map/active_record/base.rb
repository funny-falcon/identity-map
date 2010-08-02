module ActiveRecord
  class Base
	module IdentityMap
	  module ClassMethods
		private
		  def use_id_map
			extend IdMapClassMethods
			include IdMapInstanceMethods
			class << self
			  alias_method_chain :find, :identity_map
			  alias_method_chain :instantiate, :identity_map
			end
			alias_method_chain :create, :identity_map
		  end
	  end
	  
	  module IdMapClassMethods

		def id_map
		  thread_id_map.try(:for_class, self)
		end
		
		def if_id_map
		  map = id_map
		  yield map if map
		end
		
        def find_all_by_id(ids)
          if_id_map do |map|
            if ids.is_a?(Array)
              fetch_from_map(ids){|not_cached| find(:all, :conditions=>{primary_key=>not_cached})}
            else
              [ find_by_id(args0) ]
            end
          end || find(:all, :conditions=>{primary_key=>ids})
        end

        def find_by_id(ids)
          if_id_map do |map|
            if ids.is_a?(Array)
              to_find = nil
              result = fetch_from_map(ids){|not_cached| to_find = not_cached}
              unless result.empty?
                result.first
              else
                return find(:first, :conditions=>{primary_key=>to_find})
              end
            else
              map[args0]
            end
          end || find(:first, :conditions=>{primary_key=>ids})
        end

		private
          def fetch_from_map(ids, result, to_find)
            result, not_cached = [], []
            ids.each do |id|
              if ( obj << map[id] )
                result << obj
              else
                not_cached << id
              end
            end
            result.concat( yield not_cached ) unless not_cached.empty?
            result
          end
	  
		  def find_with_identity_map( *args )
			if_id_map do |map|
			  unless args.size > 1 && args[1].values.any?
				args0 = args[0]
				if args0.is_a?(Array)
				  fetch_from_map( args0, &method(:find_without_identity_map) )
				else
				  map[args0]
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
			id = create_without_identidy_map
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

