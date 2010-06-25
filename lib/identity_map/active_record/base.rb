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
		  thread_id_map && thread_id_map.for_class(self)
		end
		
		def if_id_map
		  map = id_map
		  yield map if map 
		end
		
		private
	  
		  def find_idmap_get(map, id)
			map[ id ] ||= find_without_identity_map(id)
		  end
		  
		  def find_with_identity_map( *args )
			if_id_map do |map|
			  unless args.size > 1 && args[1].values.any?
				args0 = args[0]
				if args0.is_a?(Array)
				  return args0.map{|id| find_idmap_get(map,id)}
				else
				  return find_idmap_get(map, args0)
				end
			  end
			end
			find_without_identity_map(*args)
		  end
		  
		  def instantiate_with_identity_map( record )
			if_id_map do |map|
			  id = record[primary_key]
			  object = ( map[id] ||= instantiate_without_identity_map( record ) )
			  object.instance_variable_get( :@attributes ).merge!( record )
			  return object
			end
			instantiate_without_identity_map( record )
		  end
	  end
	  
	  module IdMapInstanceMethods
		private
		  def create_with_identity_map
			id = create_without_identidy_map
			self.class.if_id_map{|map| map[id] = self }
		  end
	  end
	end
	
	extend IdentityMap::ClassMethods
  end
end

