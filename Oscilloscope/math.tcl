#File: math.tcl
#Syscomp CircuitGear
#Waveform Math Toolbox

#JG
#Copyright 2009 Syscomp Electronic Design
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

.menubar.tools.toolsMenu add command	\
	-label "Math Toolbox"	\
	-command {math::showMath}
.menubar.tools.toolsMenu add separator

namespace eval math {

set mathEnabled 0
set mathMode add

set mathHeader [image create photo -file "$images/Math.gif"]
set mathImage [image create photo -file "$images/m1V.gif"]

set verticalBoxM 1.0
set verticalIndexM 7

set mathImages [image create photo -file "$images/m5mV.gif"]
lappend mathImages [image create photo -file "$images/m10mV.gif"]
lappend mathImages [image create photo -file "$images/m20mV.gif"]
lappend mathImages [image create photo -file "$images/m50mV.gif"]
lappend mathImages [image create photo -file "$images/m100mV.gif"]
lappend mathImages [image create photo -file "$images/m200mV.gif"]
lappend mathImages [image create photo -file "$images/m500mV.gif"]
lappend mathImages [image create photo -file "$images/m1V.gif"]
lappend mathImages [image create photo -file "$images/m2V.gif"]
lappend mathImages [image create photo -file "$images/m5V.gif"]
lappend mathImages [image create photo -file "$images/m10V.gif"]
lappend mathImages [image create photo -file "$images/m20V.gif"]
lappend mathImages [image create photo -file "$images/m50V.gif"]

}

proc math::showMath {} {
	
	if $math::mathEnabled {wm deiconify .math; raise .math; focus .math; return}
	
	toplevel .math
	wm title .math "Math Toolbox"
	wm resizable .math 0 0
	bind .math <Destroy> {math::hideMath}
	
	label .math.title -image $math::mathHeader
	
	frame .math.mode	\
		-relief groove	\
		-borderwidth 2
	
	radiobutton .math.mode.add		\
		-text "Add: A + B"	\
		-variable math::mathMode	\
		-value add

	radiobutton .math.mode.subtract		\
		-text "Subtract: A - B"		\
		-variable math::mathMode	\
		-value subtract
		
	radiobutton .math.mode.multiply	\
		-text "Multiply: A * B"		\
		-variable math::mathMode		\
		-value multiply

	grid .math.mode.add -row 0 -column 0
	grid .math.mode.subtract -row 1 -column 0
	grid .math.mode.multiply -row 2 -column 0
	
	frame .math.mag	\
		-relief groove	\
		-borderwidth 2
		
	button .math.mag.zoomOut	\
		-image $vertical::zoomOutImage	\
		-command {math::adjustMath out}
		
	button .math.mag.zoomIn	\
		-image $vertical::zoomInImage	\
		-command {math::adjustMath in}
		
	label .math.mag.sensitivity -image $math::mathImage
	
	grid .math.mag.zoomOut -row 0 -column 0
	grid .math.mag.sensitivity -row 0 -column 1
	grid .math.mag.zoomIn -row 0 -column 2
	
	grid .math.title -row 0 -column 0
	grid .math.mode -row 1 -column 0
	grid .math.mag -row 2 -column 0
	
	#grid .measurements.auto.mathLabel -row 1 -column 3
	#grid .measurements.auto.freqMath -row 2 -column 3
	#grid .measurements.auto.periodMath -row 3 -column 3
	#grid .measurements.auto.averageMath -row 4 -column 3
	#grid .measurements.auto.maxMath -row 5 -column 3
	#grid .measurements.auto.minMath -row 6 -column 3
	#grid .measurements.auto.pkPkMath -row 7 -column 3
	#grid .measurements.auto.rmsMath -row 8 -column 3
	
	set math::mathEnabled 1
}

proc math::hideMath {} {
	
	#Get the path to the scope widgets
	set scopePath [display::getDisplayPath]
	
	$scopePath.display delete math
	
	#grid remove .measurements.auto.mathLabel
	#grid remove .measurements.auto.freqMath
	#grid remove .measurements.auto.periodMath
	#grid remove .measurements.auto.averageMath
	#grid remove .measurements.auto.maxMath
	#grid remove .measurements.auto.minMath
	#grid remove .measurements.auto.pkPkMath
	#grid remove .measurements.auto.rmsMath
	
	set math::mathEnabled 0
}

proc math::updateMath {} {

	if {!$math::mathEnabled} {
		return
	}

	#Get the path to the scope widgets
	set scopePath [display::getDisplayPath]

	$scopePath.display delete math
	
	#set dataA [lindex $export::exportData 0]
	set dataA [lindex $scope::scopeData 0]
	#set dataB [lindex $export::exportData 1]
	set dataB [lindex $scope::scopeData 1]
	#set stepA [lindex $export::exportData 2]
	set stepA [vertical::getStepSize A]
	#set stepB [lindex $export::exportData 3]
	set stepB [vertical::getStepSize B]
	
	set mathData {}
	
	set voltageA {}
	set voltageB {}
	
	#Compute the real life voltage for the A/D readings
	foreach datumA $dataA datumB $dataB {
		#lappend voltageA [scope::convertSample $datumA A]
		lappend voltageA [vertical::convertSampleVoltage $datumA A]
		#lappend voltageB [scope::convertSample $datumB B]
		lappend voltageB [vertical::convertSampleVoltage $datumB B]
	}
	
	switch $math::mathMode {
		"add" {
			foreach datumA $voltageA datumB $voltageB {
				lappend mathData [expr {$datumA + $datumB}]
			}
		} "subtract" {
			foreach datumA $voltageA datumB $voltageB {
				lappend mathData [expr {$datumA - $datumB}]
			}
		} "multiply" {
			foreach datumA $voltageA datumB $voltageB {
				lappend mathData [expr {$datumA * $datumB}]
			}
		}
	}
	
	#Create list for screen points
	set plotData {}
	
	#Some pre-calculations to speed things up
	set displayHeight [expr {$display::yAxisEnd-$display::yAxisStart}]
	set samplePeriod [timebase::getSamplingPeriod]
	
	#Determine the spacing between samples
	set displayTime [expr {10.0*$timebase::timebaseSetting}]
	set pixelTime [expr {$displayTime/($display::xAxisEnd-$display::xAxisStart)}]
	
	set triggerSample 0
		
	#Determine the first sample that should appear on the screen
	set firstSample 0
	#Determine the last sample that should appear on the screen
	set lastSample [expr {round(floor($display::xAxisEnd*1.0/$timebase::sampleIncrement*$pixelTime/$samplePeriod))}]
	
	#If the timebase changes during plotting exit gracefully
	if {($firstSample<0)||($lastSample>[llength $dataA])} {return}
	
	#Convert the bulk of the samples to screen coordinates
	for {set i $firstSample} {$i < $lastSample} {incr i} {
	
		set x [expr {$display::xAxisStart+($i-$triggerSample)*$timebase::sampleIncrement*[timebase::getSamplingPeriod]/$pixelTime}]
			
		if {($x >= $display::xAxisStart) &&  ($x < $display::xAxisEnd)} {
			set y [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([lindex $mathData $i]/(10*$math::verticalBoxM))}]
			lappend plotData $x
			lappend plotData $y
		}
	}
	
	#Straight-line interpolation to determine the position of the last samples on the right border of the display
	if {[expr $lastSample+1] < [llength $dataA]} {
		#Calculate the last point that should appear on the right border
		set x1 [lindex $plotData end-1]
		set x2 [expr {($lastSample+1)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
		
		#Calculate the border point for the math channel
		set y1 [lindex $plotData end]
		set voltage [lindex $mathData [expr {$lastSample+1}]]
		set y2 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*($voltage/(10*$math::verticalBoxM))}]
		
		set m [expr {($y1-$y2)/($x1-$x2)}]
		set b [expr {$y1-$m*$x1}]
		set yf [expr {$m*$display::xAxisEnd+$b}]
		
		#Add the last point to the list for Channel A
		lappend plotData $display::xAxisEnd
		lappend plotData $yf
		
	} else {
		#The last sample is on the border
		set x $display::xAxisEnd
		set y [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([lindex $mathData $lastSample]/(10*$math::verticalBoxM))}]
		lappend plotDataA $x
		lappend plotDataA $y
	}
	
	
	
	$scopePath.display create line	\
		$plotData		\
		-tag math		\
		-fill violet
}

proc math::adjustMath {direction} {
	
	switch $direction {
		"in" {
			set math::verticalIndexM [expr {$math::verticalIndexM - 1}]
		} "out" {
			set math::verticalIndexM [expr {$math::verticalIndexM + 1}]
		}
	}
	
	if { $math::verticalIndexM < 0} { set math::verticalIndexM 0 }
	if { $math::verticalIndexM > 12} { set math::verticalIndexM 12 }
	
	switch $math::verticalIndexM {
		0 {
			set math::verticalBoxM 0.005
			set math::mathImage [lindex $math::mathImages 0]
		} 1 {
			set math::verticalBoxM 0.01
			set math::mathImage [lindex $math::mathImages 1]
		} 2 {
			set math::verticalBoxM 0.02
			set math::mathImage [lindex $math::mathImages 2]
		} 3 {
			set math::verticalBoxM 0.05
			set math::mathImage [lindex $math::mathImages 3]
		} 4 {
			set math::verticalBoxM 0.1
			set math::mathImage [lindex $math::mathImages 4]
		} 5 {
			set math::verticalBoxM 0.2
			set math::mathImage [lindex $math::mathImages 5]
		} 6 {
			set math::verticalBoxM 0.5
			set math::mathImage [lindex $math::mathImages 6]
		} 7 {
			set math::verticalBoxM 1.0
			set math::mathImage [lindex $math::mathImages 7]
		} 8 {
			set math::verticalBoxM 2.0
			set math::mathImage [lindex $math::mathImages 8]
		} 9 {
			set math::verticalBoxM 5.0
			set math::mathImage [lindex $math::mathImages 9]
		} 10 {
			set math::verticalBoxM 10.0
			set math::mathImage [lindex $math::mathImages 10]
		} 11 {
			set math::verticalBoxM 20.0
			set math::mathImage [lindex $math::mathImages 11]
		} 12 {
			set math::verticalBoxM 50.0
			set math::mathImage [lindex $math::mathImages 12]
		}
	}
	
	.math.mag.sensitivity configure -image $math::mathImage
	
}


