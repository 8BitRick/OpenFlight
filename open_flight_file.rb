# This class is still very much in development
# Right now it will basically open an open flight file and let you grab binary chunks for records
# This is also VERY not optimized yet

# Refer to OpenFlight Specification PDF for explanation of OpenFlight file layout
# http://www.presagis.com/products_services/standards/openflight/more/openflight_specifications/

require 'matrix'

# Add simpler vector method names to Vector class
class Vector
  def dot(v) self.inner_product(v) end
  def cross(v) self.cross_product(v) end
end

class OpenFlightFile

  def open_file file_name
    # TODO - add some file error checking
    @file_packed = File.binread file_name
    ui2 = @file_packed.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
    @length_of_header = ui2[1]
    @file_version = ui2[7]

    h = @file_packed.unpack('H*')
    bytes = h[0].scan(/.{2}/)
    byte_buffer = bytes[@length_of_header .. -1]
    @records_packed = [byte_buffer.join].pack('H*')
  end

  def packed_record_data; @records_packed end

  # Base method to pull data from records
  def get_records_with_filter (&block)
    ui2 = @records_packed.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
    records = []

    ui2_size = ui2.size
    offset = 0
    ptr = ui2

    while(offset < ui2_size) do
      curr_record_type = ptr[0]
      record_size = ptr[1]
      offset += (record_size/2)

      yield records, curr_record_type, offset, ptr

      ptr = ptr[(record_size/2)..-1]
    end

    records
  end

  def get_first_record_with_filter (&block)
    ui2 = @records_packed.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
    record = nil

    ui2_size = ui2.size
    offset = 0
    ptr = ui2

    while(offset < ui2_size) do
      curr_record_type = ptr[0]
      record_size = ptr[1]
      offset += (record_size/2)

      if yield curr_record_type, offset, ptr
        record = (ptr[0..offset].pack('S>*'))
        break
      end

      ptr = ptr[(record_size/2)..-1]
    end

    record
  end

  # Returns an array of all record types found
  # Records are in order found in file
  def get_record_types
    get_records_with_filter {|records, record_type, offset, ptr| records.push(ptr[0])}
  end

  # Returns a hash with count of each record type
  def get_record_types_count
    Hash[Hash[get_record_types.group_by {|x| x}.map {|k,v| [k,v.count]}].sort] # counts of each record type
  end

  def get_records_of_type requested_record_type
    get_records_with_filter do |records, record_type, offset, ptr|
      if record_type == requested_record_type
        records.push(ptr[0..offset].pack('S>*'))
      end
    end
  end

  def get_first_record_of_type requested_record_type
    get_first_record_with_filter {|record_type, offset, ptr| record_type == requested_record_type}
  end

  def get_all_face_vertex_indices
    return @face_vertex_indices unless @face_vertex_indices.nil?

    face_records = get_records_of_type 72
    vertex_offsets = get_vertex_offsets

    @face_vertex_indices ||= face_records.map do |f|
      thing = f
      ui4 = thing.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
      ui2 = thing.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'

      num_verts = (ui2[1] - 4) / 4
      verts = (0...num_verts).map{|v| vertex_offsets.index(ui4[1+v])}
    end
  end

  def read_vertices_from_buffer
    records = get_records_of_type 70
    vertex_list = records.map do |v|
      thing = v
      d8 = thing.unpack 'G*' # d8 contains 'double 8 byte'
      d8[1..3]
    end
  end

  def get_face_names
    records = get_records_of_type 5
    face_names = records.map do |v|
      thing = v
      c1 = thing.unpack 'C*'
      name_bytes = c1[4...12]
      name = name_bytes.pack('C*').unpack('A*')[0]
    end
  end

  def get_vertex_list
    @vertex_list ||= read_vertices_from_buffer
  end

  def get_faces
    return @faces unless @faces.nil?

    vertex_list = get_vertex_list
    face_vertex_indicies = get_all_face_vertex_indices
    face_names = get_face_names
    # Fetch the vertex positions and put into faces
    @faces ||= face_vertex_indicies.map.with_index do |f,i|
      # Convert to math vectors to perform math operations
      vecs = f.map {|v| Vector.elements(vertex_list[v])}
      local_vecs = [(vecs[0] - vecs[1]).normalize, (vecs[2] - vecs[1]).normalize]
      normal = local_vecs[0].cross_product(local_vecs[1]).normalize
      cos_angle = normal.inner_product(Vector[0,0,1])
      angle = Math.acos(cos_angle) * (180 / Math::PI)
      face_name = face_names[i]
      # Now construct the new face object hash
      {v: vecs, n: normal, angle: angle, name: face_name}
    end
  end

  # This is necessary because faces have vertex offset positions instead of indices
  # This vertex offset list will help align faces with their vertices
  def build_vertex_offset_list
    vertex_offsets =
        get_records_with_filter do |records, record_type, offset, ptr|
          new_vertex_offset = case record_type
                                when 68 then 40 # Color
                                when 69 then 56 # Color, Normal
                                when 70 then 64 # Color, Normal, UV
                                when 71 then 48 # Color, UV
                                else nil
                              end
          records.push(new_vertex_offset) unless new_vertex_offset.nil?
        end
    vertex_offsets.insert(0, 8)
    cumulative = 0
    vertex_offsets.map{|vo| cumulative += vo}
  end

  def get_vertex_offsets
    @vertex_offsets ||= build_vertex_offset_list
  end
end
