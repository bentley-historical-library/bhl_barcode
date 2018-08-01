class BHLBarcode
  def self.find_by_barcode(model, params)
      if model[params]
          model.to_jsonmodel(model[params][:id])
      else
          {:error => "#{model} not found for params #{params}"}
      end
  end

  def self.aeon_lookup(repo_id, ref_id)
    archival_object_metadata = ArchivalObject.filter(:ref_id => ref_id).
                left_outer_join(:instance, Sequel.qualify(:instance, :archival_object_id) => Sequel.qualify(:archival_object, :id)).
                left_outer_join(:sub_container, Sequel.qualify(:sub_container, :instance_id) => Sequel.qualify(:instance, :id)).
                left_outer_join(:top_container_link_rlshp, :sub_container_id => Sequel.qualify(:sub_container, :id)).
                left_outer_join(:top_container, Sequel.qualify(:top_container, :id) => Sequel.qualify(:top_container_link_rlshp, :top_container_id)).
                left_outer_join(:top_container_housed_at_rlshp, Sequel.qualify(:top_container_housed_at_rlshp, :top_container_id) => Sequel.qualify(:top_container, :id)).
                left_outer_join(:location, Sequel.qualify(:location, :id) => Sequel.qualify(:top_container_housed_at_rlshp, :location_Id)).
                select(
                  Sequel.qualify(:archival_object, :root_record_id).as(:resource_id),
                  Sequel.qualify(:archival_object, :id).as(:archival_object_id),
                  Sequel.qualify(:top_container, :id).as(:top_container_id),
                  Sequel.qualify(:top_container, :barcode).as(:container_barcode),
                  Sequel.qualify(:location, :building).as(:building),
                  Sequel.qualify(:location, :barcode).as(:location_barcode)
                ).first

    resource_id = archival_object_metadata[:resource_id]
    archival_object_id = archival_object_metadata[:archival_object_id]
    top_container_id = archival_object_metadata[:top_container_id]
    container_barcode = archival_object_metadata[:container_barcode]
    building = archival_object_metadata[:building]
    location_barcode = archival_object_metadata[:location_barcode]
    archival_object_link = "/resources/#{resource_id}#tree::archival_object_#{archival_object_id}"
    if !top_container_id.nil?
      top_container_link = "/top_containers/#{top_container_id}"
    else
      top_container_link = nil
    end

    {"archival_object_link" => archival_object_link, "top_container_link" => top_container_link, "container_barcode" => container_barcode, "building" => building, "location" => location_barcode}
  end

  def self.metadata_for_container(container_id, repo_id)
    ids_to_titles = {}
    ids_to_parents = {}
    archival_objects = []

    container_instance_ids = TopContainer.filter(Sequel.qualify(:top_container, :id) => container_id).
                    left_outer_join(:top_container_link_rlshp, Sequel.qualify(:top_container_link_rlshp, :top_container_id) => Sequel.qualify(:top_container, :id)).
                    left_outer_join(:sub_container, Sequel.qualify(:sub_container, :id) => Sequel.qualify(:top_container_link_rlshp, :sub_container_id)).
                    select(
                      Sequel.qualify(:sub_container, :instance_id).as(:instance_id)
                    ).map(:instance_id)

    container_instance_ids.each do |instance_id|
      instance_metadata = Instance.filter(Sequel.qualify(:instance, :id) => instance_id).
                          left_outer_join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:instance, :archival_object_id)).
                          left_outer_join(:sub_container, :instance_id => instance_id).
                          left_outer_join(:top_container_link_rlshp, :sub_container_id => Sequel.qualify(:sub_container, :id)).
                          left_outer_join(:top_container, :id => Sequel.qualify(:top_container_link_rlshp, :top_container_id)).
                          select(
                            Sequel.qualify(:instance, :archival_object_id).as(:archival_object_id),
                            Sequel.qualify(:archival_object, :display_string).as(:display_string),
                            Sequel.as(Sequel.lit('GetEnumValue(instance.instance_type_id)'), :instance_type),
                            Sequel.qualify(:top_container, :indicator).as(:top_container_indicator),
                          ).
                          group(Sequel.qualify(:instance, :id), Sequel.qualify(:top_container, :id)).
                          first

      display_string = instance_metadata[:display_string]
      instance_type = instance_metadata[:instance_type]
      container_indicator = instance_metadata[:top_container_indicator]
      archival_object_id = instance_metadata[:archival_object_id]

      notes = Note.filter(:archival_object_id => archival_object_id).
              select(
                Sequel.qualify(:note, :notes)
              ).all

      general_note = ""
      physfacet_note = ""
      notes.each do |note|
        parsed_note = JSON.parse(note[:notes])
        if parsed_note["type"] == "odd"
          general_note = parsed_note["subnotes"][0]["content"]
        elsif parsed_note["type"] == "physfacet"
          physfacet_note = parsed_note["content"][0]
        end
      end

      extents = Extent.filter(:archival_object_id => archival_object_id).
                select(
                  Sequel.qualify(:extent, :number).as(:number),
                  Sequel.as(Sequel.lit('GetEnumValue(extent.extent_type_id)'), :extent_type),
                  Sequel.qualify(:extent, :physical_details).as(:physfacet)
                ).all

      extent_metadata = []
      extents.each do |extent|
        extent_number_type = "#{extent[:number]} #{extent[:extent_type]}"
        physfacet = extent[:physfacet]
        extent_metadata.push({"extent" => extent_number_type, "physfacet" => physfacet})
      end

      hierarchy_parts = []
      child_id = archival_object_id
      while child_id
        if ids_to_parents.include?(child_id)
          parent_id = ids_to_parents[child_id]
        else
          parent_id = ArchivalObject[:id => child_id][:parent_id]
          ids_to_parents[child_id] = parent_id
        end

        if parent_id.nil?
          child_id = false
        else
          if ids_to_titles.include?(parent_id)
            parent_display_string = ids_to_titles[parent_id]
          else
            parent_display_string = ArchivalObject[:id => parent_id][:display_string]
            ids_to_titles[parent_id] = parent_display_string
          end
          hierarchy_parts.push(parent_display_string)
          child_id = parent_id
        end
      end

      hierarchy = hierarchy_parts.reverse.join(" > ")
      archival_object_metadata = {"item_title" => display_string, 
                                  "hierarchy" => hierarchy,
                                  "extents" => extent_metadata, 
                                  "archival_object_id" => archival_object_id,
                                  "archival_object_uri" => "/repositories/#{repo_id}/archival_objects/#{archival_object_id}",
                                  "general_note" => general_note,
                                  "physfacet_note" => physfacet_note}

      archival_objects << archival_object_metadata
    end

    {"archival_objects" => archival_objects}
  end



  def self.containers_for_resource(resource_id)
    resource_instance_ids = ArchivalObject.filter(:root_record_id => resource_id).
                  join(:instance, :archival_object_id => Sequel.qualify(:archival_object, :id)).
                  where(Sequel.lit('GetEnumValue(instance.instance_type_id) != "digital_object"')).
                  select(
                    Sequel.qualify(:instance, :id).as(:instance_id)
                  ).map(:instance_id)

    containers = []
    seen_ids = []

    resource_instance_ids.each do |instance_id|
      instance_metadata = Instance.filter(Sequel.qualify(:instance, :id) => instance_id).
                          left_outer_join(:sub_container, :instance_id => instance_id).
                          left_outer_join(:top_container_link_rlshp, :sub_container_id => Sequel.qualify(:sub_container, :id)).
                          left_outer_join(:top_container, :id => Sequel.qualify(:top_container_link_rlshp, :top_container_id)).
                          select(
                            Sequel.as(Sequel.lit('GetEnumValue(instance.instance_type_id)'), :instance_type),
                            Sequel.as(Sequel.lit('GetEnumValue(top_container.type_id)'), :top_container_type),
                            Sequel.qualify(:top_container, :indicator).as(:top_container_indicator),
                            Sequel.qualify(:top_container, :id).as(:top_container_id)
                          ).
                          group(Sequel.qualify(:instance, :id), Sequel.qualify(:top_container, :id)).
                          first
      
      top_container_id = instance_metadata[:top_container_id]
      if !seen_ids.include?(top_container_id)
        container_info = {}
        container_info["id"] = top_container_id
        container_info["indicator"] = instance_metadata[:top_container_indicator]
        container_info["container_type"] = instance_metadata[:top_container_type]
        container_info["instance_type"] = instance_metadata[:instance_type]
        containers << container_info
        seen_ids << top_container_id
      end

    end

    {"containers" => containers}
  end
end