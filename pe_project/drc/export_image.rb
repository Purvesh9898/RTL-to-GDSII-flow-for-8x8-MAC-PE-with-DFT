layout = RBA::Layout::new
layout.read("pe_layout.gds")
view = RBA::LayoutView::new
view.load_layout("pe_layout.gds", 0)
view.max_hier
view.zoom_fit
view.save_image("pe_layout.png", 1200, 1200)
