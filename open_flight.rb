# Class to read OpenFlight files and analyze polygons
# Usage:
#
# load 'open_flight.rb'
# my_file = OpenFlight.new 'my_open_flight_file.flt'  # Opens the open flight file
# my_file.faces     # returns a hash array of all faces
# my_file.triangles # returns a hash array of all triangles
# my_file.quads     # returns a hash array of all quads
# my_file.other_polygons   # returns a hash array of all non-triangles and non-quads
# my_file.bad_polygons    # returns a hash array of non-planar quads and polygons with collocated vertices
#
# Each polygon hash is in the form of:
# [{:v=>
#[Vector[X, Y, Z],
# Vector[X, Y, Z],
# Vector[X, Y, Z]],
#    :n=>Vector[X, Y, Z],
#    :angle=>Float,
#:name=>"name_string"}]
#
# angle is relative to positive Z
# name is the long ID of the polygon

load 'internal/open_flight_file.rb'

class OpenFlight
  def initialize file_name
    @file = OpenFlightFile.new
    @file.open_file file_name
  end

  def record_types; @record_types ||= @file.get_record_types end
  def vertex_list; @vertex_list ||= @file.get_vertex_list end

  def faces; @faces ||= @file.get_faces end
  def triangles; @file.triangles end
  def quads; @file.quads end
  def other_polygons; @file.other_polygons end
  def bad_polygons; @file.bad_polygons end
end
