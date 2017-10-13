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

end