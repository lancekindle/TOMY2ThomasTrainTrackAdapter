// Lance Kindle - an adapter between two plastic train tracks.
// a wider, taller, brown track & a shorter, slimmer blue one.
// tracks are in same position, luckily. Parameters that you can or
// should modify are commented with "EDIT". Ctrl+f to find
// tracks traced out from picture in inkscape in vector form
// tested sizing by laser cutting. Then had to convert to dxf
/* 
https://reprap.org/forum/read.php?313,627739,714349#msg-714349
1 - Draw object in Inkscape
2 - Move object to lower left corner of page, align left/right center marker to left page border, align top/bottom center marker with the bottom page border (it may help to turn off the page shadow in Document Properties)
2* - this can be done with shrinking document size to selected object
3 - Select Objects you want to export
4 - Convert to Path: Path --> Object to Path (Ctrl+Shift+C)
5 - Flatten Beziers: Extensions --> Modify Path --> Flatten Beziers (adjust the value based on granularity you need; I use 0.1 for most things)
6 - Save as Desktop Cutting Plotter (Autocad DXF R14) .DXF file
7 - Make sure the ROBO-Master spline option is unchecked, LWPOLYLINE option is checked. I keep the base units in mm to be consistent with OpenSCAD.
7* - BASE UNITS ARE IMPORTANT! Find an option that allows you to specify mm in the Save-as-dxf dialog
*/
// Train tracks are sized to include a laser-cut portion (with
// tighter constraints to hold the track together). You can remove
// that at the bottom of this script if you wish to simply 3D print,
// though you may have to re-export joined_train_track.svg to dxf to
// get the tighter contraints (slight modifications were made to 3D
// print to get the pieces to slide together rather than fit firmly)

h2 = 11.4;  // height of larger brown train track
w2 = 45.83;  // width of brown track
W = 46; // largest width
h1 = 7.9;  // height of blue train track
H = 17;  // maximum height
L = 73;  // length of overall track
s1 = 61;  // step-out from blue track before going up
s2 = 19;  // step-out from brown track before going down
dxf_tracks_file = "joined_train_tracks.dxf";

module main_track_block() {
linear_extrude(height = H, center = false)
    import(file = dxf_tracks_file);
}

// a rough-cut slope to subtract from the main track block
module block_slope() {
polyhedron(
    points=[
     [0,s2,h2],[w2,s2,h2],[w2,s1,h1],[0,s1,h1],// bottom layer
     [0,s2,H+1],[w2,s2,H+1],[w2,s1,H+1],[0,s1,H+1], // top layer
    ], // bottom slope face
    faces=[
     [0,1,2,3],  // bottom 
     [4,5,1,0],  // front
     [7,6,5,4],  // top
     [5,6,2,1],  // right
     [6,7,3,2],  // back
     [7,4,0,3],  // left
    ]
); // sloped part of polyhedron
// now we need to create two two flat cubes that take up the
// non-sloped areas
translate([0,0,h2])
    cube(size=[W,s2,H-h2+1]);
translate([0,s1,h1])
    cube(size=[W,L-s1,H-h1+1]);
}

tw=8.3;  // track width
between_tracks = 18.4+tw;  // width between tracks
rail_height = 3.2; // measured as 3.2 on both blue/brown
tw1_start = 5.5; // track starts from side
tw1_end = tw1_start+tw;
tw2_start = tw1_start + between_tracks; // track 2 start width
tw2_end = tw2_start + tw;
th2 = 8.2; // h2 - rail_height; measured. Track height of brown side
th1= 4.9; // > as measured. h1 - rail_height; track height of blue side
// a rough-cut track w/ slope to cut from main track block
// (after block_slope has been cut away)
module track_slope() {
    //brown track intro
    translate([tw1_start,0,th2])
        cube(size=[tw,s2,rail_height+1]);
    translate([tw2_start,0,th2])
        cube(size=[tw,s2,rail_height+1]);
    // blue track intro
    translate([tw1_start,s1,th1])
        cube(size=[tw,L-s1,rail_height+1]);
    translate([tw2_start,s1,th1])
        cube(size=[tw,L-s1,rail_height+1]);
    // 2 sloped trapezoids from one track height to the next
    // left track
   polyhedron(
    points=[
     [tw1_start,s2,th2],[tw1_end,s2,th2],[tw1_end,s1,th1],[tw1_start,s1,th1],// bottom layer
     [tw1_start,s2,h2+1],[tw1_end,s2,h2+1],[tw1_end,s1,h1+1],[tw1_start,s1,h1+1], // top layer
    ], // bottom slope face
    faces=[
     [0,1,2,3],  // bottom 
     [4,5,1,0],  // front
     [7,6,5,4],  // top
     [5,6,2,1],  // right
     [6,7,3,2],  // back
     [7,4,0,3],  // left
    ]
   );
   // right track
   polyhedron(
    points=[
     [tw2_start,s2,th2],[tw2_end,s2,th2],[tw2_end,s1,th1],[tw2_start,s1,th1],// bottom layer
     [tw2_start,s2,h2+1],[tw2_end,s2,h2+1],[tw2_end,s1,h1+1],[tw2_start,s1,h1+1], // top layer
    ], // bottom slope face
    faces=[
     [0,1,2,3],  // bottom 
     [4,5,1,0],  // front
     [7,6,5,4],  // top
     [5,6,2,1],  // right
     [6,7,3,2],  // back
     [7,4,0,3],  // left
    ]
   );
}

// make small cuts into track to provide traction
// EDIT slat_w & slat_h depending on your printers settings. I was
// running with a 0.2mm layer height and a .4mm nozzle
module traction_strips() {
    slat_w = 0.4;  // I think this fits nozzle
    slat_h = 0.3;  // aka layer height + margin
    slat_repeat = slat_w * 2;
    // traction strips on slope
    // attempt to angle cube perpendicular to slope of track
    slat_angle = -90*(th2 - th1)/(s1 - s2);
    for (s = [s2 + 0.5 : slat_repeat : s1 - 0.5]) {
        // s steps through length of track. For every %mm, we
        // cut in a small notch
        distance = s - s2; // starts at 0
        percent = distance/(s1-s2);
        height = th2 - (percent * (th2 - th1));
        //left-track
        translate([tw1_start + tw/2, s, height])
            rotate([slat_angle,0,0])
                cube(size=[tw, slat_w, slat_h*2], center=true);
        // right-track
        translate([tw2_start + tw/2, s, height])
            rotate([slat_angle,0,0])
                cube(size=[tw, slat_w, slat_h*2], center=true);
    }
    //traction strips wide track beginning
    notch_begin = 8.5; // where notch on wide track begins-ish
    // we use notch because protrusion fails to print slats
    // and instead prints smaller, lower. So I got rid of slats
    // (if it works on your slicer, EDIT notch_begin to 0);
    for (s = [notch_begin + slat_w: slat_repeat : s2 - slat_w]) {
        // left track start
        translate([tw1_start + tw/2, s, th2])
            cube(size=[tw, slat_w, slat_h*2], center=true);
        // right track start
        translate([tw2_start + tw/2, s, th2])
            cube(size=[tw, slat_w, slat_h*2], center=true);
    }
    //traction strips slim track end
    for (s = [s1 + slat_w: slat_repeat : L - slat_w]) {
        // left track start
        translate([tw1_start + tw/2, s, th1])
            cube(size=[tw, slat_w, slat_h*2], center=true);
        // right track start
        translate([tw2_start + tw/2, s, th1])
            cube(size=[tw, slat_w, slat_h*2], center=true);
    }
}

// cutout the middle portion to save time&filament
mx = 2; // margin from sides during cutout
my = 5; // margin from ends during cutout
module middle_cutout() {
    linear_extrude(height = H)
        polygon(
            points = [ 
                [tw1_end + mx, s2 + my],
                [tw1_end + mx, s1 - my],
                [tw2_start - mx, s1 - my],
                [tw2_start - mx, s2 + my], 
            ]
        );
}

// X braces same size and location as track_cutout()
wb = 2; // width of brace
module cutout_x() {
    // create a "line" from Lower-Left corner to Upper-Right corner of cutout in middle of track
    linear_extrude(height=H - rail_height)
        polygon(
            points = [
                // L-bracket around one corner
                [tw1_end + mx + wb, s2 + my], // LL corner
                [tw1_end + mx, s2 + my], // LL corner
                [tw1_end + mx, s2 + my + wb], // LL corner
                // L bracket around opposite corner
                [tw2_start - mx - wb, s1 - my], // UR corner
                [tw2_start - mx, s1 - my], // UR corner
                [tw2_start - mx, s1 - my - wb], // UR corner
            ]
        );
    // create a "line" from one Lower-Right corner to Upper-Left corner of cutout in middle of track
    linear_extrude(height=H - rail_height)
        polygon(
            points = [
                // L-bracket around one corner
                [tw2_start - mx - wb, s2 + my],  // LR corner
                [tw2_start - mx, s2 + my],  // LR corner
                [tw2_start - mx, s2 + my + wb],  // LR corner
                // L bracket around opposite corner
                [tw1_end + mx + wb, s1 - my], // UL corner
                [tw1_end + mx, s1 - my], // UL corner
                [tw1_end + mx, s1 - my - wb], // UL corner
            ]
        );
}

module hollow_train_tracks() {
    difference() {
        main_track_block();
        middle_cutout();  // cuts out giant middle piece
        block_slope(); // cuts slope into track shape
        track_slope(); // cuts in tracks (respecting slope)
        traction_strips(); // cuts in traction strips
    }
}

module braces_for_hollow() {
    translate([0,0,-rail_height]) { // sink down braces
        difference() {
            translate([0,0,rail_height]) // push up for subtraction
                cutout_x();  // add X-bracing in cutout
            block_slope();  // create slope in X-bracing
        }
    }
}

// 1/8" acrylic height as measured. EDIT with your own measurements
laser_cut_base_h = 3.05;
module laser_cutter_base() {  // models laser-cut base
    translate([0,0,-1])
        cube(size=[W,L,laser_cut_base_h + 1]);
}

difference() {
    union() {
        hollow_train_tracks();
        braces_for_hollow();
    }
    laser_cutter_base();  // subtraces expected laser-cut base from bottom of model. 3D print will place this "hovering" model on ground. EDIT / comment this out to fully 3D print
}
