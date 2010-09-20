module ActionController
  class Base
  	module IdentityMap
  	  module InstanceMethods
        def with_identity_map
          ActiveRecord::Base.with_id_map {
            yield
          }
        end
        
        def without_identity_map
          ActiveRecord::Base.without_id_map {
            yield
          }
        end
      end
  	  
  	  module ClassMethods
  	  	def use_identity_map(*args)
  	  	  around_filter :with_identity_map, *args
  	  	end
  	  	
  	  	def dont_use_identity_map(*args)
  	  	  around_filter :without_identity_map, *args
  	  	end
  	  	
  	  	def use_dispatcher_identity_map
  	  	  if defined? ::ActionDispatch
  	  	  	ActionDispatch::Callbacks.before :create_identity_map
  	  	  	ActionDispatch::Callbacks.after :remove_identity_map
  	  	  else
  	  	  	ActionController::Dispatcher.before_dispatch :create_identity_map
  	  	  	ActionController::Dispatcher.after_dispatch :remove_identity_map
  	  	  end
  	  	end
  	  end
  	  

  	end
    extend IdentityMap::ClassMethods
    include IdentityMap::InstanceMethods
    helper_method :with_identity_map, :without_identity_map
  end
end

module DispatcherMethods
  def create_identity_map
    ActiveRecord::Base.create_identity_map
  end
  
  def remove_identity_map
    ActiveRecord::Base.drop_identity_map
  end
end

if defined? ::ActionDispatch
  ActionDispatch::Callbacks.send :include, DispatcherMethods
else
  ActionController::Dispatcher.send :include, DispatcherMethods
end
