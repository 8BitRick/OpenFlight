OpenFlight
==========

OpenFlight file reader in ruby.

This script was created primarily to do analysis on OpenFlight model polygons.

Built and tested with ruby 2.1.2.
There is only one function 'Vector.cross_product' that I know was introduced after ruby 1.9.3

Refer to OpenFlight Specification PDF for explanation of OpenFlight file layout
http://www.presagis.com/products_services/standards/openflight/more/openflight_specifications/

# Usage

```
load 'open_flight.rb'
my_file = OpenFlight.new 'my_open_flight_file.flt'  # Opens the open flight file
faces = my_file.faces     # returns a hash array of all faces
triangles = my_file.triangles # returns a hash array of all triangles
quads = my_file.quads     # returns a hash array of all quads
op = my_file.other_polygons   # returns a hash array of all non-triangles and non-quads
bp = my_file.bad_polygons    # returns a hash array of non-planar quads and polygons with collocated vertices
```

Each polygon hash is in the form of:

```
[{:v=>
 [Vector[X, Y, Z],
 Vector[X, Y, Z],
 Vector[X, Y, Z]],
    :n=>Vector[X, Y, Z],
    :angle=>Float,
:name=>"name_string"}]
```

* angle is relative to positive Z
* name is the long ID of the polygon

# FAQ

* What can I do with this?
  * You can read in open flight files, then analyze the polygons to see if anything doesn't look quite right
* What is OpenFlight?
  * OpenFlight is a standard 3D model format more commonly used in GIS and simulation. It is similar to Open Scene Graph.
* Why use ruby?
  * Because I like ruby. Many programmers who work this this kind of data probably come from a background in C++ and C#, like myself.
  * I have found ruby to be much more flexible than C++/C##/Java and find data analysis and processing to be much easier.
  * Once you have a file loaded into ruby it easier to ask questions and to send this data to text files in various forms.
