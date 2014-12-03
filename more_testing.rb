# Another loose file to help me with testing and development
# Please ignore this file

#require_relative 'open_flight_file'
load 'open_flight_file.rb'

class TestOF
  def initialize
    @file = OpenFlightFile.new
    @file.open_file 'test.flt'
    @record_types = @file.get_record_types
    @record_hash = @file.get_record_types_count
    @records = @file.get_records_of_type 2
    @face_vertex_indices = @file.get_all_face_vertex_indices
    @faces = @file.get_faces
    @vertex_list = @file.get_vertex_list
  end

  def record_types; @record_types end
  def face_vertex_indices; @face_vertex_indices end
  def faces; @faces end
  def vertex_list; @vertex_list end
  def record_hash; @record_hash end
end
