# This file is just being used to hold my random code chunks as I builds the OpenFlightFile class
# Please ignore this file
conf.return_format = "=> limited output\n %.512s\n"

f = File.binread 'test.flt'
h = f.unpack('H*')
h4 = h[0].scan(/.{8}/) # h4 contains 4 byte chunks
ui4 = f.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
ui2 = f.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'

bytes = h[0].scan(/.{2}/)

length_of_header = ui2[1]
file_version = ui2[7]

byte_buffer = bytes[length_of_header .. -1]
bytes_packed = [byte_buffer.join].pack('H*')

ui4 = bytes_packed.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
ui2 = bytes_packed.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'

record_types = get_all_record_types bytes_packed  # Get all record types
res=Hash[record_types.group_by {|x| x}.map {|k,v| [k,v.count]}] # counts of each record type

# get faces
# This will kill it
# faces = get_records_of_type 5, bytes_packed

def get_records_with_filter (packed_byte_buffer, &block)
  ui2 = packed_byte_buffer.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
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

def get_all_record_types packed_byte_buffer
  get_records_with_filter (packed_byte_buffer) {|records, record_type, offset, ptr| records.push(ptr[0])}
end

def get_records_of_type requested_record_type, packed_byte_buffer
  get_records_with_filter (packed_byte_buffer) do |records, record_type, offset, ptr|
    if record_type == requested_record_type
      records.push(ptr[0..offset].pack('S>*'))
    end
  end
end

def get_first_record_with_filter (packed_byte_buffer, &block)
  ui2 = packed_byte_buffer.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
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

requested_record_type = 5
first_face = get_first_record_with_filter(bytes_packed) {|record_type, offset, ptr| record_type == requested_record_type}

thing = first_face
ui4 = thing.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
ui2 = thing.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'

requested_record_type = 72
thing = get_first_record_with_filter(bytes_packed) {|record_type, offset, ptr| record_type == requested_record_type}
ui4 = thing.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
ui2 = thing.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'

num_verts = (ui2[1] - 4) / 4
verts = (0...num_verts).map{|v| ui4[1+v]}

records = get_records_of_type 70, bytes_packed
thing = records[1]
ui4 = thing.unpack 'L>*' # ui4 contains 'unsigned int 4 byte'
ui2 = thing.unpack 'S>*' # ui2 contains 'unsigned int 2 byte'
d8 = thing.unpack 'G*' # d8 contains 'double 8 byte'
h = thing.unpack 'H*'
h4 = h[0].scan(/.{8}/) # h4 contains 4 byte chunks
