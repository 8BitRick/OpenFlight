# Another loose file to help me with testing and development
# Please ignore this file

#require_relative 'open_flight_file'
require 'matrix'
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
  def packed_record_data; @file.packed_record_data end
end

conf.return_format = "=> limited output\n %.512s\n"

t=TestOF.new
faces = t.faces
normals = faces.map{|f| f[:n]}
angles = faces.map{|f| f[:angle]}
angle_list = Hash[Hash[angles.group_by {|a|a}.map{|k,v| [k,v.count]}].sort]
tf = faces.select{|f| f[:angle] == 45.0}
faces.index(tf[0])
v2 = Vector[0,1,0]
v3 = Vector[0,2,1]
v2.dot(v3)
pd = t.packed_record_data
# faces = t.faces.map{|f| {v: f, n: nil}}
# vecs = faces[0][:v].map{|v| Vector.elements(v)}
# local_vecs = [(vecs[0] - vecs[1]).normalize, (vecs[2] - vecs[1]).normalize]
# normal = local_vecs[0].cross_product(local_vecs[1])
# cos_angle = normal.inner_product(Vector[0,0,1])
# angle = Math.acos(cos_angle) * (180 / Math::PI)

#c1 = thing.unpack 'C*'
#a1 = thing.unpack 'a*'
#name_bytes = c1[4...12]
#name = name_bytes.pack('C*').unpack('A*')
#name = name_bytes.map{|c| c.chr}
