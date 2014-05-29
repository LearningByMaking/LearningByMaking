#File: interpolation.tcl
#Syscomp USB Oscilloscope GUI
#Scope Interpolation Procedures

#JG
#Copyright 2008 Syscomp Electronic Design
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

namespace eval interpolate {


}

proc interpolate::interpolate {plotData} {
	global pData
	global rData
	
	set pData $plotData

	if {$scope::timebaseIndex > 3} {
		return
	}

	set numSamples [llength $plotData]
	
	set average 0
	foreach sample $plotData {
		set average [expr {$average+$sample}]
	}
	set average [expr {$average*1.0/$numSamples}]
	
	set returnData {}
	lappend returnData [lindex $plotData 2]
	lappend returnData [lindex $plotData 3]
	for {set i 5} {$i < $numSamples} {set i [expr {$i+4}]} {
		set x1 [lindex $plotData [expr {$i-3}]]
		set y1 [lindex $plotData [expr {$i-2}]]
		set x2 [lindex $plotData [expr {$i-1}]]
		set y2 [lindex $plotData [expr {$i-0}]]
		
		set interpolateTime [expr {($x2-$x1)/5.0}]
		
		#P0
		lappend returnData $x2
		lappend returnData $y2
		
	#P1
		lappend returnData [expr {$x2+$interpolateTime}]
		lappend returnData [expr {(($y2-$average)*0.94+(-0.16)*($y1-$average))+$average}]
		
		#P2
		lappend returnData [expr {$x2+2*$interpolateTime}]
		lappend returnData [expr {(($y2-$average)*0.76+(-0.22)*($y1-$average))+$average}]
		
		#P3
		lappend returnData [expr {$x2+3*$interpolateTime}]
		lappend returnData [expr {(($y2-$average)*(-0.5)+(-0.19)*($y1-$average))+$average}]
		
		#P4
		lappend returnData [expr {$x2+4*$interpolateTime}]
		lappend returnData [expr {(($y2-$average)*(-0.23)+(-0.16)*($y1-$average))+$average}]
		
	}
	
	set rData $returnData
	
	set scopePath [getScopePath]
	
	$scopePath.display delete interpTag
	$scopePath.display create line	\
		$returnData	\
		-tag interpTag	\
		-fill black
}