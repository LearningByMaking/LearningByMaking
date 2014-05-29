#File: interpolation.tcl
#Syscomp CircuitGear Graphic User Interface
#Interpolation Routines

#JG
#Copyright 2014 Syscomp Electronic Design
#www.syscompdesign.com

#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License as
#published by the Free Software Foundation; either version 2 of
#the License, or (at your option) any later verison.
#
#This program is distributed in the hope that it will be useful, but
#WITHOUT ANY WARRANTY; without even the implied warranty of
#MECHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
#the GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
#USA


#THIS IS EXPERIMENTAL - IF YOU ARE READING THIS, YOU ARE VERY BRAVE

namespace eval interpolation {

}

set pi [expr acos(-1.0)]

set M 100
set fc 0.1

#Create the filter kernel
set kernel {}
set sum 0
for {set i 0} {$i <= $M} {incr i} {
	if {$i == [expr {$M/2}]} {
		set h [expr {2*$pi*$fc*(0.54-0.46*cos(2*$pi*$i/$M)+0.08*cos(4*$pi*$i/$M))}]
	} else {
		set h [expr {sin(2*$pi*$fc*($i-$M/2.0))/($i-$M/2.0)*(0.54-0.46*cos(2*$pi*$i/$M)+0.08*cos(4*$pi*$i/$M))}]
	}
	lappend kernel $h
	set sum [expr {$sum+$h}]
}
for {set i 0} {$i <= $M} {incr i} {
	set kernel [lreplace $kernel $i $i [expr {[lindex $kernel $i]/$sum}]]
}

#set fid [open kernel.csv w]
#foreach k $kernel {
#	puts $fid $k
#}
#close $fid

proc interpolation::sincInterpolation {sampledData} {
	
	#Zero pad the data
	set padded {}
	for {set i 0} {$i < [expr [llength $sampledData]]} {incr i} {
		lappend padded [lindex $sampledData $i]
		lappend padded 1023
		lappend padded 1023
		lappend padded 1023
		lappend padded 1023
	}
	
	#Filter the interpolated data	
	for {set i $::M} {$i < [llength $padded]} {incr i} {
		set Y 0
		for {set j 0} {$j <= $::M} {incr j} {
			set X [lindex $padded [expr {$i-$j}]]
			set H [lindex $::kernel $j]
			set Y [expr {$Y + $X * $H}]
		}
		set padded [lreplace $padded $i $i $Y]
	}
	
	return $padded
	
}

proc interpolation::interpolate {sampledData} {

	set interp {}
	for {set i 1} {$i < [expr [llength $sampledData]-2]} {incr i} {
		
		set y0 [lindex $sampledData [expr {$i-1}]]
		set y1 [lindex $sampledData [expr {$i}]]
		set y2 [lindex $sampledData [expr {$i+1}]]
		set y3 [lindex $sampledData [expr {$i+2}]]
		
		lappend interp $y1
		lappend interp [interpolation::cubic 0.2 $y0 $y1 $y2 $y3]
		lappend interp [interpolation::cubic 0.4 $y0 $y1 $y2 $y3]
		lappend interp [interpolation::cubic 0.6 $y0 $y1 $y2 $y3]
		lappend interp [interpolation::cubic 0.8 $y0 $y1 $y2 $y3]
	}
	
	return $interp
	
}

proc interpolation::cubic {mu y0 y1 y2 y3} {
	
	set mu2 [expr {$mu*$mu}]
	
	set a0 [expr {$y3-$y2-$y0+$y1}]
	set a1 [expr {$y0-$y1-$a0}]
	set a2 [expr {$y2-$y0}]
	set a3 $y1
	
	return [expr {$a0*$mu*$mu2 + $a1*$mu2 + $a2*$mu + $a3}]
}

