module ActionController # :nodoc:
  class Base # :nodoc:
    module IdentityMap # :nodoc:
      module InstanceMethods
        # Execute block with identity map.
        #
        # If it called with +true+, then new instance of identity map would be used
        # regardless of any present.
        #
        # If it called with +false+, then it only ensures that identity map created if absent.
        #
        # Default is +true+
        #
        # Typical usage is around filter, which is most times better than direct call.
        # 
        # Usage:
        #   class ThingsController
        #     def action1
        #       with_identity_map do
        #         #some_actions
        #       end
        #     end
        #     #around_filter :with_identity_map, :only => :action2
        #     use_identity_map :only => :action2
        #     def action2
        #       #some_actions
        #     end
        #   end
        #
        # Method declared as a helper method, so could be used in a views.  
        def with_identity_map( fresh = true )
          ActiveRecord::Base.with_id_map(fresh) {
            yield
          }
        end
        
        # Temporary disables identity map.
        #
        # Could be used if identity map introduced undesired behaviour.
        #
        # Usage:
        #   class ThingsController
        #     def action1
        #       without_identity_map do
        #         #some_actions
        #       end
        #     end
        #     around_filter :without_identity_map, :only => :action2
        #     def action2
        #       #some_actions
        #     end
        #   end
        # Method declared as a helper method, so could be used in a views.  
        def without_identity_map
          ActiveRecord::Base.without_id_map {
            yield
          }
        end
      end
      
      module ClassMethods
        # Puts around filter which is enable identity map usage for actions.
        #
        # <tt>use_identity_map *args</tt> is shorthand for <tt>around_filter :with_identity_map, *args</tt>
        #
        # Typically you could put it in a ApplicationController
        #   class ApplicationController
        #     use_identity_map
        #   end
        def use_identity_map(*args)
          around_filter :with_identity_map, *args
        end
        
        # Puts around filter which is disable identity map usage for actions.
        #
        # <tt>dont_use_identity_map *args</tt> is shorthand for <tt>around_filter :without_identity_map, *args</tt>
        #
        # Typically you would call it if undesired behaviour were introduced by identity_map
        #   class ThingsController
        #     dont_use_identity_map :only => :some_strange_action
        #   end
        def dont_use_identity_map(*args)
          around_filter :without_identity_map, *args
        end
        
        # Put identity map creation onto lower level, actually on a dispatcher
        # may be for use in a Metal or Rack actions
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
# :enddoc:
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
