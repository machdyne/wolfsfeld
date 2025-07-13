/*
 * Wolfsfeld Case
 * Copyright (c) 2025 Lone Dynamics Corporation. All rights reserved.
 *
 * required hardware:
 *  - 4 x M3 x 25mm bolts
 *  - 4 x M3 nuts
 *
 */
 
 
wolfsfeld_top();
color([0,1,0]) translate([0,0,0.35]) wolfsfeld_back();
translate([0,0,-5.5]) wolfsfeld_bottom();

//translate([0,-4,-0.8]) wolfsfeld_pcb();
 
 module wolfsfeld_pcb() {
     difference() {
        color([0,1,0]) translate([-80/2,-60/2,-1.6/2]) roundedcube(80,60,1.6,4);
        translate([-40+4,-30+4,-5]) cylinder(d=3.2, h=100, $fn=36);
        translate([40-4,-30+4,-5]) cylinder(d=3.2, h=100, $fn=36);
        translate([-40+4,30-4,-5]) cylinder(d=3.2, h=100, $fn=36);
        translate([40-4,30-4,-5]) cylinder(d=3.2, h=100, $fn=36);
     }
     // keyboard
     color([0.3,0.3,0.3]) translate([0,0,20/2+0.8]) cube([80,20,20], center=true);
     // display
     color([0.3,0.3,0.5]) translate([-(27.6/2),22.28,13]) cube([35,12,3], center=true); 
     // reset
     color([0.3,0.3,0.3]) translate([-40,17.27,7.5/2+0.8]) cube([7.5,7.5,7.5], center=true);
     // power
     color([0.3,0.3,0.3]) translate([-40,-15.92,3/2+0.8]) cube([7.5,7.5,3], center=true);
     // trrs
     color([0.3,0.3,0.3]) translate([40,16.58,7.5/2]) cube([7.5,7.5,7.5], center=true);
     // mmod
     color([0.3,0.3,0.3]) translate([-1.18,27-6.8,3/2]) cube([15,7.5,3], center=true);
     // pmod
     color([0.3,0.3,0.3]) translate([19.6,27-0.8,-3/2]) cube([15,7.5,3], center=true);
     // zwölf
     color([0.3,0.3,0.3]) translate([19.6,27-0.8,3/2]) cube([16.5,7.5,3], center=true);
     // zwölf springs
     color([0.7,0.7,0.7]) translate([19.6,27-0.8,4]) cube([15,5,3], center=true);
 }
 
 module wolfsfeld_top() {
     
//    translate([0,0,8]) color([1,0,0]) cube([84,72,16], center=true);

    // display edge
    translate([0,9.75,14]) cube([80,5,2], center=true);

    // battery edges
    difference() {
        translate([0,-15.5,15]) cube([80,1.75,5], center=true);
        translate([0,32.75,5]) rotate([45,0,0]) cube([100,50,100], center=true);
    }
    translate([0,7,13]) cube([80,2,5], center=true);

    difference() {
        translate([0,-4,0]) {
            translate([-40+4,-30+4,0.15]) cylinder(d=8, h=17, $fn=36);
            translate([40-4,-30+4,0.15]) cylinder(d=8, h=17, $fn=36);
            translate([-40+4,30-4,10]) cylinder(d=8, h=4, $fn=36);
            translate([40-4,30-4,10]) cylinder(d=8, h=4, $fn=36);
        }
        translate([0,-4,0]) {
            translate([-40+4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([-40+4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            
            translate([-40+4,-30+4,13]) cylinder(d=6, h=6, $fn=36);
            translate([40-4,-30+4,13]) cylinder(d=6, h=6, $fn=36);
            translate([-40+4,30-4,14]) cylinder(d=6, h=2, $fn=36);
            translate([40-4,30-4,14]) cylinder(d=6, h=2, $fn=36); 
            
        }
    }
    
    difference() {

        union() {
            
            // above keys
            difference() {
                union() { 
                    minkowski() {
                        translate([-(84-4)/2,-(72-4)/2,1]) roundedcube(84-4,72-4,16-3,4);
                        sphere(2);
                    }
                }
                translate([0,-40,0]) cube([100,50,100], center=true);
            }

            // below keys
            difference() {
                union() { 
                    minkowski() {
                        translate([-(84-4)/2,-(72-4)/2,1]) roundedcube(84-4,72-4,19-3,4);
                        sphere(2);
                    }
                }
                translate([0,32.75,5]) rotate([45,0,0]) cube([100,50,100], center=true);
                
            }
            
        }

        
        translate([0,0,-0.65]) cube([100,100,1.5], center=true);

        translate([-80/2,-68/2,-2]) roundedcube(80,68,16,4);

        color([1,0,0]) translate([-80/2,-68/2,1]) roundedcube(80,38,16,4);


        translate([0,-4,0]) {

            // keyboard cutout
            translate([-80/2,-20/2,-20]) roundedcube(80,20,50,4);

            // display cutout
            translate([-(27.6/2)+2,22.28,0]) cube([28,12,50], center=true); 
            
            // display board cutout
            translate([-(27.6/2)+2,22.28,-10]) cube([38.5,12,50], center=true); 

            // reset button
            translate([-40,17.27,7.5/2]) cube([7.5,7.5,7.5], center=true);    

            // power switch
            translate([-40,-15.92,2.25/2]) cube([7.5,7.5,2.25], center=true);    

            // trrs jack
            translate([40,16.58,7.5/2]) cube([7.5,7.5,7.5], center=true);

            // zwolf access
            translate([18.5,45,3/2]) cylinder(d=25, h=100);
            
            // back cutout
            translate([0,40,0]) cube([70.5,5,28], center=true); 

            // bolt sink holes
            translate([-40+4,-30+4,13]) cylinder(d=6, h=6, $fn=36);
            translate([40-4,-30+4,13]) cylinder(d=6, h=6, $fn=36);
            translate([-40+4,30-4,14]) cylinder(d=6, h=2, $fn=36);
            translate([40-4,30-4,14]) cylinder(d=6, h=2, $fn=36);        
        
            // bolt holes
            translate([-40+4,-30+4,-5]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,-30+4,-5]) cylinder(d=3.2, h=100, $fn=36);
            translate([-40+4,30-4,-5]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,30-4,-5]) cylinder(d=3.2, h=100, $fn=36);
        
            // logos
            translate([0,-22.5,18.5])
                linear_extrude(1)
                    text("W O L F S F E L D", size=3, halign="center", font="Lato Black");
                    
            translate([18,20,10])
                linear_extrude(10)
                    text("/ / /", size=5, halign="center", font="Lato Black");

                            
        }
        
    }

     
 }

module wolfsfeld_back() {
    
    difference() {
        union() {
            
            // back panel
            translate([0,35,13.5/2]) cube([70,2,13.5], center=true); 
    
            // display support
            translate([-11+15,26,6]) cube([54,18,8], center=true); 
            translate([-11+20,26,4]) cube([4.75,18,8], center=true); 
            
            translate([4,40.5-10.6,9]) cube([54,10,9], center=true); 
            
            translate([-40+4,30-8,0]) cylinder(d=8, h=9.65, $fn=36);
            translate([40-4,30-8,0]) cylinder(d=8, h=9.65, $fn=36);
            
            // bolt mounts
            translate([-30,29.25,4]) cube([19.5,9.5,8], center=true); 
            translate([30,28.5,4.875]) cube([19.5,11,9.75], center=true); 

        }

        // zwolf access
        translate([18.5,41,-1]) cylinder(d=25, h=100);
        
        // zwölf cutout
        translate([18.5,30-0.8,3/2]) cube([16.5,20,10], center=true);
        translate([18.5,35-0.8,3/2]) cube([16.5,20,15], center=true);

        // mmod cutout
        translate([-1.18,14.8-0.8,3/2]) cube([17.5,40,15], center=true);

        // dev port cutout
        translate([-1.18,-35+0.8,3/2]) cube([16,30,3], center=true);

        // LED channel
        translate([40-4-6.625,29-8,-5]) cube([3.25,10,100], center=true);
        
        // bolt holes
        translate([-40+4,30-8,-5]) cylinder(d=3.5, h=100, $fn=36);
        translate([40-4,30-8,-5]) cylinder(d=3.5, h=100, $fn=36);

        // corner cutouts
        translate([-39,34,5]) cube([5,5,20], center=true); 
        translate([37.5,34,5]) cube([5,5,20], center=true); 

    }

}

module wolfsfeld_bottom() {

//    color([1,0,0]) translate([-84/2,-72/2,0]) roundedcube(84,72,6,4);
    
    difference() {
        translate([0,-4,0]) {
            translate([-40+4,-30+4,2]) cylinder(d=9, h=4-1.6, $fn=36);
            translate([40-4,-30+4,2]) cylinder(d=9, h=4-1.6, $fn=36);
            translate([-40+4,30-4,2]) cylinder(d=9, h=4-1.6, $fn=36);
            translate([40-4,30-4,2]) cylinder(d=9, h=4-1.6, $fn=36);
        }
        translate([0,-4,0]) {
            translate([-40+4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([-40+4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            
            translate([-40+4,-30+4,0]) cylinder(d=7, h=3, $fn=6);
            translate([40-4,-30+4,0]) cylinder(d=7, h=3, $fn=6);
            translate([-40+4,30-4,0]) cylinder(d=7, h=3, $fn=6);
            translate([40-4,30-4,0]) cylinder(d=7, h=3, $fn=6);
        }
    }

     difference() {
         
        minkowski() {
            translate([-(84-4)/2,-(72-4)/2,2]) roundedcube(84-4,72-4,6-3,4);
            sphere(2);
        }
        
        translate([0,0,7.5-1]) cube([100,100,1.5], center=true);
        
        translate([-80.25/2,-68.25/2,2]) roundedcube(80.25,68.25,15,4);

        // zwolf access
        translate([18.5,45-4,-1]) cylinder(d=25, h=100);
        
        // mmod / pmod
        translate([18.5,40,7]) cube([16.5,20,10], center=true);

        // dev port
        translate([0,-35+0.8,4.3]) cube([21,30,3+1.6], center=true);

        translate([0,-4,0]) {
            translate([-40+4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,-30+4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([-40+4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            translate([40-4,30-4,0]) cylinder(d=3.2, h=100, $fn=36);
            
            translate([-40+4,-30+4,0]) cylinder(d=7, h=3, $fn=6);
            translate([40-4,-30+4,0]) cylinder(d=7, h=3, $fn=6);
            translate([-40+4,30-4,0]) cylinder(d=7, h=3, $fn=6);
            translate([40-4,30-4,0]) cylinder(d=7, h=3, $fn=6);
        }
    }
    
}
 
// https://gist.github.com/tinkerology/ae257c5340a33ee2f149ff3ae97d9826
module roundedcube(xx, yy, height, radius)
{
    translate([0,0,height/2])
    hull()
    {
        translate([radius,radius,0])
        cylinder(height,radius,radius,true);

        translate([xx-radius,radius,0])
        cylinder(height,radius,radius,true);

        translate([xx-radius,yy-radius,0])
        cylinder(height,radius,radius,true);

        translate([radius,yy-radius,0])
        cylinder(height,radius,radius,true);
    }
}
