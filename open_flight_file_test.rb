# These are unit tests for OpenFlightFile class
require 'test/unit'
require_relative 'open_flight_file'

class OpenFlightFileTests < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @file = OpenFlightFile.new
    @file.open_file 'test.flt'
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Tests
  def test_get_record_types
    record_types = @file.get_record_types
    assert_not_empty record_types
    assert_equal 182, record_types.size
  end

  def test_get_all_group_nodes
    records = @file.get_records_of_type 2
    assert_equal 3, records.size
  end

  def test_get_first_record_of_type
    assert_not_nil @file.get_first_record_of_type 5
  end

  def test_get_faces_vertex_lists
    faces = @file.get_all_face_vertex_indices
    assert_not_empty faces
    assert_equal 22, faces.size
    assert_equal 3, faces[0].size
  end

  def test_build_vertex_list
    vertex_list = @file.get_vertex_list
    assert_not_empty vertex_list
    assert_equal 36, vertex_list.size
    assert_in_epsilon 0.12442381104804777, vertex_list[1][0], 0.001, "Vertex X position is incorrect!"
    assert_in_epsilon -0.05670486439317339, vertex_list[1][1], 0.001, "Vertex Y position is incorrect!"
    assert_in_epsilon 2.128891083916551, vertex_list[1][2], 0.001, "Vertex Z position is incorrect!"
  end
end