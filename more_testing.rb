# Another loose file to help me with testing and development
# Please ignore this file

#require_relative 'open_flight_file'
#require 'profile'
#require 'benchmark'
#require 'matrix'
load 'open_flight_file.rb'

class TestOF
  def initialize
    @file = OpenFlightFile.new
    @file.open_file 'runway1.flt'
  end

  def record_types; @record_types ||= @file.get_record_types end
  def face_vertex_indices; @face_vertex_indices ||= @file.get_all_face_vertex_indices end
  def faces; @faces ||= @file.get_faces end
  def vertex_list; @vertex_list ||= @file.get_vertex_list end
  def record_hash; @record_hash ||= @file.get_record_types_count end
  def packed_record_data; @file.packed_record_data end
  def triangles; @file.triangles end
  def quads; @file.quads end
  def other_polygons; @file.other_polygons end
  def bad_polygons; @file.bad_polygons end
end

conf.return_format = "=> limited output\n %.512s\n"
t=nil
faces=nil
t=TestOF.new
faces = t.faces
#puts Benchmark.measure{t=TestOF.new}
#puts Benchmark.measure{faces = t.faces}

# normals = faces.map{|f| f[:n]}
# angles = faces.map{|f| f[:angle]}
# File.write('angles.txt', angles.compact.sort.map{|a| a.to_s}.join("\n"))
#
# bad_faces = faces.select{|f| f[:n].is_a? String}
# bf_groups = bad_faces.group_by{|f| f[:n]}
# bad_names = bad_faces.map{|f| f[:name]}
# File.write('RunwayQuads.txt', bad_names.join("\n"))
