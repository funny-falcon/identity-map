require "identity_map/cache"
if defined?(ActionController)
  require "identity_map/action_controller/dispatcher"
end
require "identity_map/active_record/base"
require "identity_map/active_record/association_preload"
