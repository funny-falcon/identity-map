module ActiveRecord
  module AssociationPreload #:nodoc:
    module ClassMethods
      def preload_has_and_belongs_to_many_association_with_identity_map(records, reflection, preload_options={})
        unless reflection.klass.respond_to?(:id_map)
          return preload_has_and_belongs_to_many_association_without_identity_map(records, reflection, preload_options)
        end
        table_name = reflection.klass.quoted_table_name
        records = records.find_all{|record| !record.send(reflection.name).loaded?}
        return if records.empty?
        id_to_record_map, ids = construct_id_map(records)
        records.each {|record| record.send(reflection.name).loaded}
        options = reflection.options

        conditions = "t0.#{reflection.primary_key_name} #{in_or_equals_for_ids(ids)}"
        conditions << append_conditions(reflection, preload_options)
        
        joins = connection.select_all(sanitize_sql([
            "select t0.#{reflection.primary_key_name} as prnt_id, t0.#{reflection.association_foreign_key} as chld_id
             from #{connection.quote_table_name options[:join_table]} t0
             where #{conditions}
             ", ids]))
        child_record_ids = joins.map{|j| j['chld_id']}.uniq

        associated_records = reflection.klass.with_exclusive_scope do
          reflection.klass.find(:all, :conditions => {reflection.klass.primary_key => child_record_ids},
            :include => options[:include],
            :select => options[:select].presence,
            :order => options[:order])
        end
        associated_record_map = associated_records.inject({}){|h, r| h[r.id.to_s] = r; h}
        joins.each do |j|
          mapped_records = id_to_record_map[j['prnt_id'].to_s]
          $stderr.puts(mapped_records.inspect + ' ' + associated_record_map[j['chld_id'].to_s].inspect)
          add_preloaded_records_to_collection(mapped_records, reflection.name, associated_record_map[j['chld_id'].to_s])
        end
        $stderr.puts("exit")
      end
      alias_method_chain :preload_has_and_belongs_to_many_association, :identity_map
      
      if Array.respond_to?(:wrap)
        def add_preloaded_records_to_collection(parent_records, reflection_name, associated_record)
          parent_records.each do |parent_record|
            association_proxy = parent_record.send(reflection_name)
            association_proxy.loaded
            associated_records = Array.wrap(associated_record) - association_proxy.target
            association_proxy.target.push(*associated_records)
            association_proxy.__send__(:set_inverse_instance, associated_record, parent_record)
          end
        end
      else
        def add_preloaded_records_to_collection(parent_records, reflection_name, associated_record)
          parent_records.each do |parent_record|
            association_proxy = parent_record.send(reflection_name)
            association_proxy.loaded
            associated_records = [associated_record].flatten - association_proxy.target
            association_proxy.target.push(*associated_records)
            association_proxy.__send__(:set_inverse_instance, associated_record, parent_record)
          end
        end
      end
    end
  end
end
