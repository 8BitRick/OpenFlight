# This class does all of the internal processing to read the OpenFlight files
# This was built and test with OpenFlight versions 16.2 and 16.4

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
    ui2 = @file_packed.unpack 'S>8' # ui2 contains 'unsigned int 2 byte'
    @length_of_header = ui2[1]
    @file_version = ui2[7]
    @records_packed = @file_packed[@length_of_header .. -1]
    @records_unpacked = @records_packed.unpack 'S>*'
  end

  def triangles; @triangles ||= @faces.select{|f| f[:v].size == 3} end
  def quads; @quads ||= @faces.select{|f| f[:v].size == 4} end
  def other_polygons; @other_polygons ||= @faces.select{|f| !triangles.include?(f) && !quads.include?(f)} end
  def bad_polygons; @bad_polygons ||= @faces.select{|f| f[:n].is_a? String} end

  def packed_record_data; @records_packed end

  # Base method to pull data from records
  def get_records_with_filter (&block)
    ui2 = @records_unpacked
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
    ui2 = @records_unpacked
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

  # def get_records_of_type requested_record_type
  #   get_records_with_filter do |records, record_type, offset, ptr|
  #     if record_type == requested_record_type
  #       records.push(ptr[0..offset].pack('S>*'))
  #     end
  #   end
  # end

  def get_records_of_type requested_record_type
    ui2 = @records_unpacked
    records = []

    ui2_size = ui2.size
    offset = 0
    ptr = ui2
    record_byte_offset = 0
    record_type_array = Array(requested_record_type)

    while(offset < ui2_size) do
      curr_record_type = ptr[offset]
      record_size = ptr[offset+1]

      offset += (record_size/2)

      #yield records, curr_record_type, offset, ptr
      #do |records, record_type, offset, ptr|
          if record_type_array.include? curr_record_type
            #records.push(ptr[record_byte_offset...record_byte_offset+record_size].pack('S>*'))
            records.push(@records_packed[record_byte_offset...record_byte_offset+record_size])
          end
      #end

      record_byte_offset += record_size
      #ptr = ptr[(record_size/2)..-1]
    end

    records
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
    records = get_records_of_type [68, 69, 70, 71]
    vertex_list = records.map do |v|
      thing = v
      d8 = thing.unpack 'G*' # d8 contains 'double 8 byte'
      d8[1..3]
    end
  end

  def get_face_names
    # This is not pretty but is necessary to find the real names of polygons
    # Each face record (type 5) may optionally be followed by a "Long ID record" (type 33)
    # For this reason we must keep track of when we are directly following a face record
    # Then we know to replace the old face name with the new one from our "Long ID record"

    ui2 = @records_unpacked
    records = []

    ui2_size = ui2.size
    offset = 0
    ptr = ui2
    name = ''
    following_face_record = false

    while(offset < ui2_size) do
      curr_record_type = ptr[0]
      record_size = ptr[1]
      offset += (record_size/2)

      if following_face_record && curr_record_type == 33
        # This is the long name for the face
        old_name = records.pop
        raw_data = ptr[0..(record_size/2)].pack('S>*')
        thing = raw_data
        c1 = thing.unpack 'C*'
        name_bytes = c1[4...record_size]
        name = name_bytes.pack('C*').unpack('A*')[0]
        records.push(name)
      end

      if curr_record_type == 5
        raw_data = ptr[0..(record_size/2)].pack('S>*')
        thing = raw_data
        c1 = thing.unpack 'C*'
        name_bytes = c1[4...12]
        name = name_bytes.pack('C*').unpack('A*')[0]
        records.push(name)
        following_face_record = true
      else
        following_face_record = false
      end

      ptr = ptr[(record_size/2)..-1]
    end

    records
  end

  def get_face_short_names
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

      vlist=[]

      if vecs.size == 3
        vlist.push(vecs[0] - vecs[1])
        vlist.push(vecs[1] - vecs[2])
      elsif vecs.size >= 4
        vlist.push(vecs[0] - vecs[1])
        vlist.push(vecs[1] - vecs[2])
        vlist.push(vecs[2] - vecs[3])
      end

      vert_pairs=vlist.each_cons(2).to_a
      results = vert_pairs.map do |vp|
        if vp.all?{|v| v.norm > 0.001}
          local_vecs = [vp[0].normalize, vp[1].normalize]
          normal = local_vecs[0].cross_product(local_vecs[1]).normalize
          cos_angle = normal.inner_product(Vector[0,0,1])
          cos_angle = [-1,cos_angle,1].sort[1] # limit to range (-1..1)
          angle = Math.acos(cos_angle) * (180 / Math::PI)
        else
          normal = 'collocated vertices'
          angle = nil
        end
        {n: normal, a: angle}
      end

      face_name = face_names[i]

      case results.size
        when 1
          # Great this is a triangle
          normal = results[0][:n]
          angle = results[0][:a]
        when 2
          # This is a quad
          # Compare normals on the quad (ensure they are close to pointing same direction)
          if results.any?{|r| r[:n].is_a? String}
            normal = 'collocated vertices'
            angle = nil
          else
            cos_angle = results[0][:n].inner_product(results[1][:n])
            cos_angle = [-1,cos_angle,1].sort[1] # limit to range (-1..1)
            angle = Math.acos(cos_angle) * (180 / Math::PI)
            if angle < 0.01
              normal = results[0][:n]
              angle = results[0][:a]
            else
              normal = 'Non-planar quad'
              angle = nil
            end
          end
        when results.size > 2
          # Some other dimension polygon
          # Skip our normal checks for now
          normal = results[0][:n]
          angle = results[0][:a]
        else
          # Mutated non-polygon
          normal = 'Non-polygon, num vertices = ' + vecs.size
          angle = nil
      end

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
