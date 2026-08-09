layout = RBA::Layout::new
layout.read("pe_layout.gds")
puts "Top cell: " + layout.top_cell.name
puts "Total cells: " + layout.cells.to_s
puts "Layers: " + layout.layers.to_s
bbox = layout.top_cell.bbox
puts "Bounding box (DBU): " + bbox.to_s
puts "Bounding box (microns): " + (bbox.width/1000.0).to_s + " x " + (bbox.height/1000.0).to_s
