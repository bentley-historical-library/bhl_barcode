# BHL Barcode
This ArchivesSpace plugin adds functionality for various aspects of the Bentley Historical Library's container and folder barcoding work, including assigning locations to containers and prepping folders for digitization.

## Directory Structure
    backend\
        controllers\
            bhl_barcode.rb
        model\
            bhl_barcode.rb
    frontend\
        views\
            top_containers\
                bulk_operations\
                    _results.html.erb

## How it Works
The backend modifications include several API endpoints, defined in `backend/controllers/bhl_barcode.rb`, which return information based on certain parameters. Each API endpoint calls a function of the `BHLBarcode` class, defined in `backend/model/bhl_barcode.rb`, which interacts with the ArchivesSpace database. The API endpoints are defined in detail below.

The HTML template at `frontend/views/top_containers/bulk_operations/_results.html.erb` overrides the default template for search results displayed by the ArchivesSpace Manage Top Containers functionality. The customization modifies the default template by hiding the columns "ILS Holding ID" and "Exported to ILS." This file should be compared against the default template in the ArchivesSpace repository for each new ArchivesSpace release.

## API Endpoints

### `GET /repositories/:repo_id/find_by_barcode/container`
Description: Get a Top Container for a given barcode

#### Parameters
* `:repo_id`: The Repository ID
* `barcode`: The Top Container's barcode

#### Example URI
`/repositories/2/find_by_barcode/container?barcode=12346789`

#### Returns
If the barcode is found, this endpoint returns the ArchivesSpace JSONModel representation of the Top Container. If the barcode is not found, it returns `{:error: 'TopContainer not found for params {:repo_id => [repo_id], :barcode => [barcode]}'}`

### `GET /repositories/:repo_id/find_by_barcode/location`
Description: Get a Location for a given barcode

#### Parameters
* `:repo_id`: The Repository ID
* `barcode`: The Location's barcode

#### Example URI
`/repositories/2/find_by_barcode/location?barcode=NCRC-123-A`

#### Returns
If the barcode is found, this endpoint returns the ArchivesSpace JSONModel representation of the Location. If the barcode is not found, it returns `{:error: 'Location not found for params {:repo_id => [repo_id], :barcode => [barcode]}'}`

### `GET /repositories/:repo_id/containers_for_resource/:id`
Description: Get Top Container info for a Resource

#### Parameters
* `:repo_id`: The Repository ID
* `:id`: The Resource ID

#### Example URI
`/repositories/2/containers_for_resource/123`

#### Returns
Returns a JSON object of `{"containers": [containers]}` with `[containers]` representing an array of metadata for each Top Container associated as an Instance with the given Resource. Each item in the array is a hash with key:value pairs consisting of:

* id: The Top Container ID
* indicator: The Top Container's indicator
* container_type: The Top Container's type (e.g., "box," "folder," etc.)
* instance_type: The Instance Type of the Instance with which the Top Container is associated (e.g., "Box," "Folder," "Oversize Box," etc.)

### `GET /repositories/:repo_id/metadata_for_container/:id`
Description: Get descriptive metadata associated with a Top Container

#### Parameters
* `:repo_id`: The Repository ID
* `:id`: The Top Container ID

#### Example URI
`/repositories/2/metadata_for_container/456`

#### Returns
Returns a JSON object of `{"archival_objects": [archival_objects]}` with `[archival_objects]` representing an array of metadata for all Archival Objects with which a given Top Container is associated. Each item in the array is a hash with key:value pairs consisting of:

* item_title: The Archival Object's display string
* hierarchy: The intellectual hierarchy/breadcrumb trail to the Archival Object (i.e., Series > Subseries > File)
* extents: An array with each item representing an Extent subrecord associated with the Archival object with key:value pairs consisting of:
  * extent: The Extent's number and type
  * physfacet: Physical Details associated with the Extent subrecord
* archival_object_id: The Archival Object's ID
* archival_object_uri: The Archival Object's URI
* general_note: A note of type `odd` associated with the Archival Object
* physfacet_note: A note of type `physfacet` associated with the Archival Object

### `GET /repositories/:repo_id/aeon_lookup`
Description: Lookup information for Aeon

#### Parameters
* `:repo_id`: The Repository ID
* `ref_id`: An Archival Object's ref_id

#### Example URI
`/repositories/2/aeon_lookup?ref_id=819a01dea8aa4c708e68e17a1a0868ad`

#### Returns
Returns a JSON object containing a hash with metadata for the Archival Object with the given ref_id. The hash contains key:value pairs consisting of:

* archival_object_link: A direct link to the Archival Object in the ArchivesSpace staff interface
* top_container_link: A direct link to a Top Container associated with the Archival Object in the ArchivesSpace staff interface
* container_barcode: The barcode for a Top Container associated with the Archival Object 
* building: The building for a Location at which a Top Container associated with the Archival Object is located
* location: The barcode for a Location at which a Top Container associated with the Archival Object is located
* accessrestrict: A Boolean value indicating whether or not the Archival Object or any of its parent Archival Object's has a note of type `accessrestrict`