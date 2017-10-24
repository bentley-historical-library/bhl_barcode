class BHLBarcode
  def self.find_by_barcode(model, params)
      if model[params]
          model.to_jsonmodel(model[params][:id])
      else
          {:error => "#{model} not found for params #{params}"}
      end
  end

  def self.containers_for_resource(resource_id)
    resource_instance_ids = ArchivalObject.filter(:root_record_id => resource_id).
                  join(:instance, :archival_object_id => Sequel.qualify(:archival_object, :id)).
                  where(Sequel.lit('GetEnumValue(instance.instance_type_id) != "digital_object"')).
                  select(
                    Sequel.qualify(:instance, :id).as(:instance_id)
                  ).map(:instance_id)

    ids_to_titles = {}
    ids_to_parents = {}
    container_info = {}

    resource_instance_ids.each do |instance_id|
      instance_metadata = Instance.filter(Sequel.qualify(:instance, :id) => instance_id).
                          left_outer_join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:instance, :archival_object_id)).
                          left_outer_join(:sub_container, :instance_id => Sequel.qualify(:instance, :id)).
                          left_outer_join(:top_container_link_rlshp, :sub_container_id => Sequel.qualify(:sub_container, :id)).
                          left_outer_join(:top_container, :id => Sequel.qualify(:top_container_link_rlshp, :top_container_id)).
                          left_outer_join(:extent, :archival_object_id => Sequel.qualify(:archival_object, :id)).
                          select(
                            Sequel.qualify(:instance, :archival_object_id).as(:archival_object_id),
                            Sequel.as(Sequel.lit('GROUP_CONCAT(CONCAT(extent.number, " ", GetEnumValue(extent.extent_type_id)) SEPARATOR "; ")'), :extents),
                            Sequel.qualify(:archival_object, :display_string).as(:display_string),
                            Sequel.as(Sequel.lit('GetEnumValue(instance.instance_type_id)'), :instance_type),
                            Sequel.qualify(:top_container, :id).as(:top_container_id),
                            Sequel.qualify(:top_container, :indicator).as(:top_container_indicator),
                            Sequel.as(Sequel.lit('GetEnumValue(top_container.type_id)'), :container_type)
                          ).first

      instance_type = instance_metadata[:instance_type]
      container_indicator = instance_metadata[:top_container_indicator]
      display_string = instance_metadata[:display_string]
      extents = instance_metadata[:extents]
      if not container_info.include?(instance_type)
        container_info[instance_type] = {}
      end

      if not container_info[instance_type].include?(container_indicator)
        container_info[instance_type][container_indicator] = []
      end

      hierarchy_parts = []
      archival_object_id = instance_metadata[:archival_object_id]

      while archival_object_id
        if ids_to_titles.include?(archival_object_id)
          title = ids_to_titles[archival_object_id]
          parent_id = ids_to_parents[archival_object_id]
        else
          title = ArchivalObject[:id => archival_object_id][:display_string]
          parent_id = ArchivalObject[:id => archival_object_id][:parent_id]
          ids_to_titles[archival_object_id] = title
          ids_to_parents[archival_object_id] = parent_id
        end

        hierarchy_parts.push(title)

        if parent_id.nil?
          archival_object_id = false
        else
          archival_object_id = parent_id
        end
      end

      hierarchy = hierarchy_parts.reverse.join(" > ")
      container_info[instance_type][container_indicator].push({"item_title" => display_string, "hierarchy" => hierarchy, "extents" => extents})
    end

    container_info
  end
end