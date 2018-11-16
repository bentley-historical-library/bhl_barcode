class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/find_by_barcode/container')
    .description("Get a Top Container for a given barcode")
    .params(["repo_id", :repo_id],
            ["barcode", String])
    .permissions([:view_repository])
    .returns([200, "TopContainer JSON"]) \
  do
    json_response(BHLBarcode.find_by_barcode(TopContainer, {:repo_id => params[:repo_id], :barcode => params[:barcode]}))
  end

  Endpoint.get('/repositories/:repo_id/find_by_barcode/location')
    .description("Get a Location for a given barcode")
    .params(["repo_id", :repo_id],
            ["barcode", String]
            )
    .permissions([:view_repository])
    .returns([200, "Location JSON"]) \
  do
    json_response(BHLBarcode.find_by_barcode(Location, {:barcode => params[:barcode]}))
  end

  Endpoint.get('/repositories/:repo_id/containers_for_resource/:id')
    .description("Get Top Container info for a Resource")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "Container Info"]) \
  do
    json_response(BHLBarcode.containers_for_resource(params[:id]))
  end

  Endpoint.get('/repositories/:repo_id/metadata_for_container/:id')
    .description("Get descriptive metadata associated with a Top Container")
    .params(["repo_id", :repo_id],
            ["id", :id])
    .permissions([:view_repository])
    .returns([200, "Container Metadata"]) \
  do
    json_response(BHLBarcode.metadata_for_container(params[:id], params[:repo_id]))
  end

  Endpoint.get('/repositories/:repo_id/aeon_lookup')
    .description("Lookup information for Aeon")
    .params(["repo_id", :repo_id],
            ["ref_id", String])
    .permissions([:view_repository])
    .returns([200, "Aeon information"]) \
  do
    json_response(BHLBarcode.aeon_lookup(params[:repo_id], params[:ref_id]))
  end

end