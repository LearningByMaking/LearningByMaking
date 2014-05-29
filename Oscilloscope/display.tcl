#File: display.tcl
#Syscomp CircuitGear Graphic User Interface
#Display Routines

#JG
#Copyright 2010 Syscomp Electronic Design
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

#Procedure Index - display.tcl
#	display::setDisplayPath
#	display::getDisplayPath
#	display::buildDisplay
#	display::buildGraph
#	display::setMode
#	display::resizeDisplay
#	display::moveGripper
#	display::drawAxes
#	display::plotData
#	display::getDisplayHeight
#	display::getDisplayWidth
#	display::outOfDate
#	display::plotScan
#	display::plotStrip
#	display::clearDisplay
#	display::graphPlotX
#	display::xAxisLabels
#	display::xZoom
#	display::xScroll
#	display::xScrollService
#	display::autoScaleX
#	display::autoScrollX
#	display::createGridPopup
#	display::updateScrollMode
#	display::showGraphSettings
#	display::checkGraphLimit
#	display::updateMarker
#	display::toggleXYMode
#	display::plotXY
#	


namespace eval display {

#Scope Display Geometry
set minimumGraphWidth 400
set minimumGraphHeight 400
set graphWidth 400
set graphHeight 400
set leftMargin 20
set rightMargin 20
set bottomMargin 15
set topMargin 15
set yAxisStart $topMargin
set yAxisEnd [expr {$graphHeight-$bottomMargin}]
set xAxisStart $leftMargin
set xAxisEnd [expr {$graphWidth-$rightMargin}]

#Location to display state information
set stateDisplayX [expr {$xAxisStart + 10}]
set stateDisplayY [expr {$yAxisEnd + 2}]

#Display Widget
set displayPath .

#Grid Parameters
set axisColor black
set backgroundColor white
set xGridColor grey
set yGridColor grey
set xGridEnabled 1
set yGridEnabled 1

#Trace Colors
set channelAColor red
set channelBColor blue

#Graph Zoom Controls
set zoomInImage [image create photo -file "$::images/ZoomIn.gif"]
set zoomOutImage [image create photo -file "$::images/ZoomOut.gif"]

#Display/Graph State
set displayMode normal

#Graph Display Parameters
set xMin 0
set xStart 0
set xEnd 10
set xSpan 10
set scrollMode autoScroll
set autoScrollEnable 1
set autoScaleEnable 0

#XY Mode
set xyEnable 0

}

#---=== Procedures ===---#

# display::setDisplayPath
#
# Assigns the widget path for the display widget.
proc display::setDisplayPath {newDisplayPath} {
	variable displayPath
	
	set displayPath $newDisplayPath
}

# display::getDisplayPath
#
# Returns the current widget path for the display widget.
proc display::getDisplayPath {} {
	variable displayPath
	
	return $displayPath
}

# display::buildDisplay
#
# Constructs the scope display widget.  setDisplayPath must be called
# first to set the widget path.
proc display::buildDisplay {} {

	set displayPath [getDisplayPath]
	
	#Scope status bar
	label $displayPath.statusBar	\
		-height -2	\
		-relief groove	\
		-text ""
	
	#Main display canvas
	canvas $displayPath.display	\
		-background $display::backgroundColor	\
		-width $display::graphWidth	\
		-height $display::graphHeight	
	
	#Small handle label for resizing the display	
	label $displayPath.gripper	\
		-image [image create photo -file "$::images/Gripper.gif"]
	
	bind $displayPath.gripper <Button-1> {set display::gripperStart [list %X %Y]}
	bind $displayPath.gripper <B1-Motion> {display::moveGripper %X %Y}
	
	#Create pop-up menus
	cursor::createCursorPopup "$displayPath.display"
	display::createGridPopup "$displayPath.display" normal
	
	#Create ground reference cursors
	cursor::drawChAGndCursor
	cursor::drawChBGndCursor
	
	#Draw the trigger level cursor
	cursor::drawTriggerCursor
	
	#Draw the trigger point cursor
	cursor::drawXCursor
	
}

# display::buildGraph
#
# Builds the widgets for the graph display (strip chart mode).  setDisplayPath must be called
# first to set the display widget path.
proc display::buildGraph {} {

	#Build the widgets for the strip chart graph
	set displayPath [getDisplayPath]
	
	#Main canvas for the graph display
	canvas $displayPath.graph	\
		-background $display::backgroundColor	\
		-width $display::graphWidth	\
		-height $display::graphHeight	\
		-xscrollcommand "$displayPath.xScroll.scroller set"
		
	#Frame to hold the x-axis zoom controls
	frame $displayPath.xScroll
	scrollbar $displayPath.xScroll.scroller	\
		-orient horizontal	\
		-command display::xScroll
	button $displayPath.xScroll.zoomIn	\
		-image $display::zoomInImage	\
		-command {display::xZoom in}
	button $displayPath.xScroll.zoomOut	\
		-image $display::zoomOutImage	\
		-command {display::xZoom out}
	grid $displayPath.xScroll.zoomOut -row 0 -column 0
	grid $displayPath.xScroll.scroller -row 0 -column 1 -sticky we
	grid columnconfig $displayPath.xScroll 1 -weight 1
	grid $displayPath.xScroll.zoomIn -row 0 -column 2
	
	#Create pop-up menus
	cursor::createCursorPopup "$displayPath.graph"
	display::createGridPopup "$displayPath.graph" strip

}

# display::setMode
# 
# Selects the oscilloscope display or the strip chart display.  Places the appropriate widgets
# and calls all procedures necessary to update the display/graph after the change.
proc display::setMode {mode} {
	variable displayMode

	set displayPath [getDisplayPath]

	if {$mode=="strip"} {

		#Remove the sampling display
		grid forget $displayPath.statusBar
		grid forget $displayPath.display
		grid forget $displayPath.gripper
	
		#Show the strip chart display
		grid $displayPath.statusBar -row 0 -column 0 -sticky we
		grid $displayPath.graph -row 1 -column 0
		grid $displayPath.gripper -row 1 -column 0 -sticky se -ipadx 0 -pady 0 -padx 0 -pady 0
		grid $displayPath.xScroll -row 2 -column 0 -sticky we
		
		raise $displayPath.gripper
	
		set displayMode strip
		
		#Redraw any cursors that are enabled
		cursor::drawChAGndCursor
		cursor::drawChBGndCursor
		cursor::reDrawTimeCursors
		cursor::reDrawChACursor
		cursor::reDrawChBCursor
	} else {
		#Remove the strip chart display
		grid forget $displayPath.statusBar
		grid forget $displayPath.graph
		grid forget $displayPath.gripper
		grid forget $displayPath.xScroll
		
		#Show the sampling display
		grid $displayPath.statusBar -row 0 -column 0 -stick we
		grid $displayPath.display -row 1 -column 0
		grid $displayPath.gripper -row 1 -column 0 -sticky se -ipadx 0 -pady 0 -padx 0 -pady 0
		raise $displayPath.gripper
	
		set displayMode normal
		
		#Redraw any cursors that are enabled
		cursor::drawChAGndCursor
		cursor::drawChBGndCursor
		cursor::reDrawTimeCursors
		cursor::reDrawChACursor
		cursor::reDrawChBCursor
	}
	
	display::drawAxes
}

# display::resizeDisplay
#
# This procedure is a handler for the resize gripper.  It resizes the display and calls
# all necessary procedures to update the graphics on the display.  Input parameters are the
# new width (w) and height (h) of the display.
proc display::resizeDisplay {w h} {
	variable yAxisStart
	variable yAxisEnd
	variable xAxisStart
	variable xAxisEnd
	variable displayMode
	
	
	#Save the new geometry
	set display::graphWidth $w
	set display::graphHeight $h
	
	#Make sure we don't make the graph too small
	if {$display::graphWidth < $display::minimumGraphWidth} {
		set display::graphWidth $display::minimumGraphWidth
	}
	if {$display::graphHeight < $display::minimumGraphHeight} {
		set display::graphHeight $display::minimumGraphHeight
	}
	
	#Make sure the display is square
	if {$display::graphHeight!=$display::graphWidth} {
		set display::graphWidth $display::graphHeight
	}

	#Resize the scope display and the strip chart
	[getDisplayPath].display configure -width $display::graphWidth -height $display::graphHeight
	[getDisplayPath].graph configure -width $display::graphWidth -height $display::graphHeight
	
	#Resize the plot area
	set yAxisEnd [expr {$display::graphHeight-$display::bottomMargin}]
	set newEnd [expr {$display::graphWidth-$display::rightMargin}]
	set deltaWidth [expr {$newEnd-$xAxisEnd}]
	set xAxisEnd $newEnd
	
	#Redraw the axes
	display::drawAxes
	
	#Update the channel reference positions
	cursor::reDrawChAGndCursor
	cursor::reDrawChBGndCursor
	
	#Update the trigger cursor
	cursor::reDrawTriggerCursor
	
	#Update the trigger point cursor
	cursor::reDrawXCursor
	
	#Update the measurement cursors
	cursor::reDrawChACursor
	cursor::reDrawChBCursor
	cursor::reDrawTimeCursors
	
	#Update the x-axis labels in strip chart mode
	if {$display::displayMode=="strip"} {
		display::xScrollService
	}
	
	#Remove the traces - they will be redrawn on the next sample update
	display::clearDisplay

}

# display::moveGripper
#
# Service routine called when the user grabs and drags the display resize gripper.  Calculates
# the change in the size of the display and calls the resizeDisplay procedure.
proc display::moveGripper {x y} {

	#Pull the last x,y coordinates
	set prevX [lindex $display::gripperStart 0]
	set prevY [lindex $display::gripperStart 1]
	
	#Calculate the change in position of the gripper
	set deltaX [expr {$x-$prevX}]
	set deltaY [expr {$y-$prevY}]

	#Resize the graph area
	display::resizeDisplay [expr {$display::graphWidth+$deltaX}] [expr {$display::graphHeight+$deltaY}]
	
	#Store the current gripper position for next time
	set display::gripperStart [list $x $y]
	
}

# display::drawAxes
#
# Draws (or redraws) the axes on the scope display.
proc display::drawAxes {} {
	variable displayMode

	#Get the widget paths for the scope display and strip chart display
	set displayPath [display::getDisplayPath]
	if {$displayMode == "normal"} {
		set displayPath "$displayPath.display"
	} else {
		set displayPath "$displayPath.graph"
	}
	
	#Remove the old axes
	$displayPath delete axis
	
	#Draw the X-Axis
	$displayPath create line	\
		$display::xAxisStart $display::yAxisEnd	\
		$display::xAxisEnd $display::yAxisEnd	\
		-tag axis	\
		-fill $display::axisColor
	$displayPath create line	\
		$display::xAxisStart $display::yAxisStart	\
		$display::xAxisEnd $display::yAxisStart	\
		-tag axis	\
		-fill $display::axisColor
		
	#Draw the Y-Axis
	$displayPath create line	\
		$display::xAxisStart $display::yAxisStart	\
		$display::xAxisStart $display::yAxisEnd	\
		-tag axis	\
		-fill $display::axisColor
	$displayPath create line	\
		$display::xAxisEnd $display::yAxisStart	\
		$display::xAxisEnd $display::yAxisEnd	\
		-tag axis	\
		-fill $display::axisColor
		
	#Draw the X-Grid
	$displayPath delete xAxisGrid
	if {$display::xGridEnabled} {
		for {set i 1} {$i <10} {incr i} {
			set x [expr {$display::xAxisStart + ($i/10.0)*($display::xAxisEnd-$display::xAxisStart)}]
			$displayPath create line	\
				$x $display::yAxisStart	\
				$x $display::yAxisEnd	\
				-tag xAxisGrid	\
				-fill $display::xGridColor	\
				-dash .
		}
	}
	
	#Draw the Y-Grid
	$displayPath delete yAxisGrid
	if {$display::yGridEnabled} {
		for {set i 1} {$i < 10} {incr i} {
			set y [expr {$display::yAxisStart + ($i/10.0)*($display::yAxisEnd-$display::yAxisStart)}]
			$displayPath create line	\
				$display::xAxisStart $y	\
				$display::xAxisEnd $y	\
				-tag yAxisGrid	\
				-fill $display::yGridColor	\
				-dash .
		}
	}
	
	#Draw y-axes and minor tick marks
	if {$display::xGridEnabled} {
		$displayPath create line	\
			[expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/2.0}] $display::yAxisStart	\
			[expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/2.0}] $display::yAxisEnd	\
			-tag xAxisGrid	\
			-fill $display::xGridColor	
		set tickLeft [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/2.0-($display::xAxisEnd-$display::xAxisStart)/100.0}]
		set tickRight [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/2.0+($display::xAxisEnd-$display::xAxisStart)/100.0}]
		for {set i 1} {$i < 50} {incr i} {
			$displayPath create line	\
				$tickLeft [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/50.0*$i}]	\
				$tickRight [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/50.0*$i}]	\
				-fill $display::xGridColor	\
				-tag xAxisGrid
		}
	}
	
	#Draw x-axes and minor tick marks
	if {$display::yGridEnabled} {
		$displayPath create line	\
			$display::xAxisStart [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0}]	\
			$display::xAxisEnd [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0}]	\
			-tag yAxisGrid	\
			-fill $display::yGridColor	
		set tickTop [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0-($display::yAxisEnd-$display::yAxisStart)/100.0}]
		set tickBottom [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0+($display::yAxisEnd-$display::yAxisStart)/100.0}]
		for {set i 1} {$i < 50} {incr i} {
			$displayPath create line	\
				[expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/50.0*$i}] $tickTop \
				[expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/50.0*$i}] $tickBottom	\
				-fill $display::yGridColor	\
				-tag yAxisGrid
		}
	}

}

# display::plotData
#
# This procedure plots the A and B traces on the oscilloscope display using the data currently stored in the 
# scope::scopeData array.
proc display::plotData {} {

	#Get the current scope data
	set dataA [lindex $scope::scopeData 0]
	set dataB [lindex $scope::scopeData 1]
	
	#Decide if we need to interpolate the data
	if {[timebase::getSamplingPeriod] < 100E-6} {
		if {$::interpEnable} {
			#set dataA [interpolation::sincInterpolation $dataA]
			#set dataB [interpolation::sincInterpolation $dataB]
			set dataA [interpolation::interpolate $dataA]
			set dataB [interpolation::interpolate $dataB]
			set samplePeriod [expr {[timebase::getSamplingPeriod]/5.0}]
			#The trigger sample is always mid-way through the sample buffer
			set triggerSample 2560
		} else {
			set triggerSample 512
			set samplePeriod [timebase::getSamplingPeriod]
		}
	} else {
		set samplePeriod [timebase::getSamplingPeriod]
		#The trigger sample is always mid-way through the sample buffer
		set triggerSample 512
	}
	
	#On the fastest timebase, the trigger point can jitter slightly, align it, if necessary
	if {([timebase::getSamplingPeriod] < 100E-6)&&($scope::triggerState ==2)} {
		#Get the trigger level, in samples
		set triggerLevel [vertical::voltageToSample $cursor::triggerVoltage $trigger::triggerSource]
		if {($trigger::triggerSource=="A")||($trigger::triggerSource=="a")} {
			set searchData $dataA
		} else {
			set searchData $dataB
		}
		for {set i 0} {$i <= 10} {incr i} {
			set prevSample [lindex $searchData [expr {$triggerSample+($i-1)}]]
			set currentSample [lindex $searchData [expr {$triggerSample+$i}]]
			if {$trigger::triggerSlope == "rising"} {
				if {($currentSample <= $triggerLevel)&&($prevSample > $triggerLevel)} {
					set triggerSample [expr {$triggerSample+$i}]
					break
				}
			} else {
				if {($currentSample >= $triggerLevel)&&($prevSample < $triggerLevel)} {
					set triggerSample [expr {$triggerSample+$i}]
					break
				}
			}
		}
	}
	
	#Create lists for screen points
	set plotDataA {}
	set plotDataB {}
	
	#Some pre-calculations to speed things up
	set displayHeight [expr {$display::yAxisEnd-$display::yAxisStart}]
	
	#Determine the spacing between samples
	set displayTime [expr {10.0*$timebase::timebaseSetting}]
	set pixelTime [expr {$displayTime/($display::xAxisEnd-$display::xAxisStart)}]
	
	#Determine the first sample that should appear on the screen
	set firstSample 0
	#Determine the last sample that should appear on the screen
	set lastSample [llength $dataA]
	set rightBorderSample [llength $dataA]
	
	#If the timebase changes during plotting exit gracefully
	if {($firstSample<0)||($lastSample>[llength $dataA])} {return}
	
	#Calculate the index of the sample that should appear immediately to the right of the left border
	set leftBorderSample [expr {round(floor($triggerSample-($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio*$pixelTime/($timebase::sampleIncrement*$samplePeriod)))}]
		
	if {$leftBorderSample > 0} {
		#Straight-line interpolation to determine the position of the last samples on the right border of the display
		set x1 [expr {($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio+$display::xAxisStart+($leftBorderSample-1-$triggerSample)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
		set x2 [expr {($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio+$display::xAxisStart+($leftBorderSample-$triggerSample)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
		#Calculate the border point for channel A
		set y1 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataA [expr {$leftBorderSample-1}]] A]/(10*[vertical::getBoxSize A]))}]
		set y2 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataA $leftBorderSample] A]/(10*[vertical::getBoxSize A]))}]
		#Straight line interpolation
		set m [expr {($y2-$y1)/($x2-$x1)}]
		set b [expr {$y1-$m*$x1}]
		set yf [expr {$m*$display::xAxisStart+$b}]
		
		lappend plotDataA $display::xAxisStart
		lappend plotDataA $yf
		
		#Calculate the border point for channel B
		set y1 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataB [expr {$leftBorderSample-1}]] B]/(10*[vertical::getBoxSize B]))}]
		set y2 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataB $leftBorderSample] B]/(10*[vertical::getBoxSize B]))}]
		#Straight line interpolation
		set m [expr {($y2-$y1)/($x2-$x1)}]
		set b [expr {$y1-$m*$x1}]
		set yf [expr {$m*$display::xAxisStart+$b}]
		
		lappend plotDataB $display::xAxisStart
		lappend plotDataB $yf
	}
	
	#Convert the bulk of the samples to screen coordinates
	for {set i $firstSample} {$i < $lastSample} {incr i} {

		set x [expr {($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio+$display::xAxisStart+($i-$triggerSample)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
			
		if {($x >= $display::xAxisStart) &&  ($x <= $display::xAxisEnd)} {
			
			set y [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataA $i] A]/(10*[vertical::getBoxSize A]))}]
			lappend plotDataA $x
			lappend plotDataA $y
		
			set y [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataB $i] B]/(10*[vertical::getBoxSize B]))}]
			lappend plotDataB $x
			lappend plotDataB $y
		}
		
		if {$x >= $display::xAxisEnd} {
			set rightBorderSample $i
			break
		}
	}
	
	if {$rightBorderSample < $lastSample} {
		#Straight-line interpolation to determine the position of the last samples on the right border of the display
		set x1 [expr {($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio+$display::xAxisStart+($rightBorderSample-1-$triggerSample)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
		set x2 [expr {($display::xAxisEnd-$display::xAxisStart)*$cursor::timeRatio+$display::xAxisStart+($rightBorderSample-$triggerSample)*$timebase::sampleIncrement*$samplePeriod/$pixelTime}]
		#Calculate the border point for channel A
		set y1 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataA [expr {$rightBorderSample-1}]] A]/(10*[vertical::getBoxSize A]))}]
		set y2 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataA $rightBorderSample] A]/(10*[vertical::getBoxSize A]))}]
		#Straight line interpolation
		set m [expr {($y2-$y1)/($x2-$x1)}]
		set b [expr {$y1-$m*$x1}]
		set yf [expr {$m*$display::xAxisEnd+$b}]
		
		lappend plotDataA $display::xAxisEnd
		lappend plotDataA $yf
		
		#Calculate the border point for channel B
		set y1 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataB [expr {$rightBorderSample-1}]] B]/(10*[vertical::getBoxSize B]))}]
		set y2 [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*([vertical::convertSampleVoltage [lindex $dataB $rightBorderSample] B]/(10*[vertical::getBoxSize B]))}]
		#Straight line interpolation
		set m [expr {($y2-$y1)/($x2-$x1)}]
		set b [expr {$y1-$m*$x1}]
		set yf [expr {$m*$display::xAxisEnd+$b}]
		
		lappend plotDataB $display::xAxisEnd
		lappend plotDataB $yf
	}
	
	#Display Persistence Service
	persist::updatePersist $plotDataA $plotDataB
	
	#Draw the Traces on the Screen
	set displayPath [display::getDisplayPath]
	
	#Channel A Trace
	$displayPath.display delete waveDataA
	if {$vertical::enableA} {
		$displayPath.display create line	\
			$plotDataA	\
			-tag waveDataA	\
			-fill $display::channelAColor
	}
	
	#Channel B Trace
	$displayPath.display delete waveDataB
	if {$vertical::enableB} {
		
		$displayPath.display create line	\
			$plotDataB	\
			-tag waveDataB	\
			-fill $display::channelBColor
	}

}

# display::getDisplayHeight
#
# Returns the height of the scope display in pixels
proc display::getDisplayHeight {} {

	return [expr {$display::yAxisEnd-$display::yAxisStart}]

}

# display::getDisplayWidth
#
# Returns the width of the scope display in pixels
proc display::getDisplayWidth {} {

	return [expr {$display::xAxisEnd-$display::xAxisStart}]
	
}

# display::outOfDate
#
# Sets the scope display as "out-of-date" by changes the traces from solid lines to dashed lines.
# Used to indicate that a setting or control has been adjusted and the change is not yet reflected
# on the display.
proc display::outOfDate {} {

	set displayPath [getDisplayPath]
	
	$displayPath.display itemconfigure waveDataA -dash .
	$displayPath.display itemconfigure waveDataB -dash .

}

# display::plotScan
#
# This procedure plots the A and B traces on the oscilloscope display using the data currently stored in the 
# strip chart data array.  The trace is drawn using whatever samples are available, even if they do not stretch
# all the way across the screen.
proc display::plotScan {} {

	#Make sure we have enough data points to draw a line
	if {$scope::stripSample < 2} {return}
	
	#Create some arrays to hold the coordinates for the traces
	set plotDataA {}
	set plotDataB {}
	
	set dataIncr 1
	
	#Some pre-calculations to speed things up
	set displayHeight [expr {$display::yAxisEnd-$display::yAxisStart}]
	set samplePeriod [timebase::getSamplingPeriod]
	
	#Determine the spacing between samples
	set displayTime [expr {10.0*$timebase::timebaseSetting}]
	set pixelTime [expr {$displayTime/($display::xAxisEnd-$display::xAxisStart)}]
	
	#Process all samples in the strip chart recorder array
	for {set i 0} {$i < [llength $scope::stripData]} {set i [expr {$i+$dataIncr}]} {
		set datum [lindex $scope::stripData $i]
		set xT [lindex $datum 1]
		set voltA [lindex $datum 2]
		set voltB [lindex $datum 3]
		
		set x [expr {$xT*1.0/$pixelTime+$display::xAxisStart}]
		set yA [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*($voltA/(10*[vertical::getBoxSize A]))}]
		set yB [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*($voltB/(10*[vertical::getBoxSize B]))}]
	
		lappend plotDataA $x $yA
		lappend plotDataB $x $yB
	}

	#Make sure the timebase setting display is up to date
	#timebase::updateIndicator
	
	#Plot the traces on the screen
	set displayPath [display::getDisplayPath]
	
	#Channel A trace
	$displayPath.display delete waveDataA
	if {$vertical::enableA} {
		$displayPath.display create line	\
			$plotDataA	\
			-tag waveDataA	\
			-fill $display::channelAColor
	}
	
	#Channel B trace
	$displayPath.display delete waveDataB
	if {$vertical::enableB} {
		
		$displayPath.display create line	\
			$plotDataB	\
			-tag waveDataB	\
			-fill $display::channelBColor
	}

}

# display::plotStrip
#
# This procedure plots the A and B traces on the strip chart display using the data currently stored in the 
# strip chart data array.
proc display::plotStrip {} {

	#Make sure there is enough data to display
	if {$scope::stripSample < 2} {return}
	
	#Remove the old traces
	set displayPath [display::getDisplayPath]
	$displayPath.graph delete waveDataA
	$displayPath.graph delete waveDataB
	
	#Check to see if we need to autoscale or autoscroll
	display::autoScaleX
	display::autoScrollX
	
	#Update the scroll bar
	display::xScrollService
	
	set plotDataA {}
	set plotDataB {}
	
	#Data sub-sampling for large data sets
	if {$display::xSpan > $display::graphWidth} {
		set dataIncr [expr {round(floor(2.0*$display::xSpan/$display::graphWidth))}]
	} else {
		set dataIncr 1
	}
	
	#Some pre-calculations to speed things up
	set displayHeight [expr {$display::yAxisEnd-$display::yAxisStart}]
	
	#Determine which samples need to be shown on the screen
	set samplesAvailable [expr {$scope::samplesOnDisk+[llength $scope::stripData]}]
	set first [expr {round(floor($display::xStart/($timebase::stripChartSamplePeriod*1.0E-3)))}]
	if {$first >= $samplesAvailable} {
		return
	}
	set last [expr {round(ceil($display::xEnd/($timebase::stripChartSamplePeriod*1.0E-3)))}]
	if {$last >= $samplesAvailable} {
		set last $samplesAvailable
	}
	if {[expr {$last-$first}]<[expr {2*$dataIncr}]} {
		return
	}
	
	#Process the data that needs to be displayed on the graph
	for {set i $first} {$i < $last} {set i [expr {$i+$dataIncr}]} {
		
		#Get this data point
		set datum [scope::getStripSample $i]
		
		#X-Coordinate for this point
		set x [lindex $datum 1]
		
		#Calculate the screen position of this sample point
		if {$x >= $display::xStart} {
			if {$x <= $display::xEnd} {
				set voltA [lindex $datum 2]
				set voltB [lindex $datum 3]
				set yA [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*($voltA/(10*[vertical::getBoxSize A]))}]
				set yB [expr {$displayHeight/2.0+$display::yAxisStart-$displayHeight*($voltB/(10*[vertical::getBoxSize B]))}]
				set x [display::graphPlotX $x]
				lappend plotDataA $x $yA
				lappend plotDataB $x $yB
			}
		}
	}

	#Make sure the timebase setting display is up to date
	#timebase::updateIndicator
	
	#Draw the new traces	
	if {$vertical::enableA} {
		$displayPath.graph create line	\
			$plotDataA	\
			-tag waveDataA	\
			-fill $display::channelAColor
	}
	if {$vertical::enableB} {
		
		$displayPath.graph create line	\
			$plotDataB	\
			-tag waveDataB	\
			-fill $display::channelBColor
	}
	

}

# display::clearDisplay
#
# Deletes the channel A and channel B traces from the oscilloscope display
# and the strip chart display
proc display::clearDisplay {} {

	set displayPath [display::getDisplayPath]
	
	$displayPath.display delete waveDataA
	$displayPath.display delete waveDataB
	
	$displayPath.graph delete waveDataA
	$displayPath.graph delete waveDataB
	
}

# display::graphPlotX
#
# Returns the x-coordinate in screen pixels corresponding to sample number (x)
proc display::graphPlotX {x} {
	variable xAxisStart
	variable xAxisEnd
	variable xStart
	variable xSpan

	return [expr {(($x*1.0-$xStart)/($xSpan))*($xAxisEnd-$xAxisStart)+$xAxisStart}]
}

# display::xAxisLabels
#
# Draws (or redraws) the x-axis labels on the strip chart graph.
proc display::xAxisLabels {} {

	#Get the graph widget path
	set displayPath [display::getDisplayPath]
	
	#Remove the old labels
	$displayPath.graph delete xAxisLabels
	
	#Place the new labels
	for {set i 0} {$i <= 10} {incr i} {
		#Calculate screen location for label
		set x [expr {$display::xAxisStart+($i/10.0)*($display::xAxisEnd-$display::xAxisStart)}]
		#Create label
		set temp [format "%.1f" [expr {$display::xSpan*($i/10.0)+$display::xStart}]]
		if {$temp>1E6} {
			set temp [format "%.1fM" [expr {$temp/1.0E6}]]
		} elseif {$temp > 1E3} {
			set temp [format "%.1fk" [expr {$temp/1.0E3}]]
		}
		#Draw the label
		$displayPath.graph create text	\
			$x [expr {$display::yAxisEnd+10}]	\
			-text $temp	\
			-tag xAxisLabels
	}
}

# display::xZoom
#
# Zooms the strip chart in or out depending on the input parameter (dir).  The args parameter
# can be used to explicitly set the midpoint of the zoom.
proc display::xZoom {dir args} {
	variable xStart
	variable xEnd
	variable xSpan
	
	#Determine if we are zooming in or out
	if {$dir == "in"} {
		#Disable auto scaling
		if {$display::scrollMode=="autoScale"} {
			set display::scrollMode disabled
		}
		#See if we need to center the zoom on a specified mid-point
		if {$args != ""} {
			set midpoint $args
		} else {
			set midpoint [expr {$xStart+$xSpan/2.0}]
		}
		#Recalculate the span of samples that we are displaying
		set xSpan [expr {floor($xSpan/1.6)}]
		if {$xSpan < 2} {
			set xSpan 2
		}
	} elseif {$dir == "out"} {
		#Disable auto scaling
		if {$display::scrollMode=="autoScale"} {
			set display::scrollMode disabled
		}
		#See if we need to center the zoom on a specified mid-point
		if {$args!=""} {
			set midpoint $args
		} else {
			set midpoint [expr {$xStart+$xSpan/2.0}]
		}
		#Recalculate the span of samples that we are displaying
		set xSpan [expr {floor($xSpan*1.6)}]
	} elseif {$dir=="update"} {
		#Just update the display, don't change the zoom
		set xSpan [expr {$display::xEnd-$display::xStart}]
		set midpoint [expr {$display::xStart+$xSpan/2.0}]
	}
	
	#Hard limit for zooming out
	if {$xSpan>100E6} {
		set xSpan 100E6
	}

	#Calculate the new starting and ending samples based on the midpoit and the new span
	set xStart [expr {$midpoint-$xSpan/2.0}]
	set xEnd [expr {$midpoint+$xSpan/2.0}]
	#Make sure the starting sample is positive
	if {$xStart<0} {
		set xStart 0
		set xEnd [expr {$xStart+$xSpan}]
	}
	#Make sure the end sample does not exceed the hard-limit
	if {$xEnd>100E6} {
		set xEnd 100E6
		set xStart 0
	}
	
	#Update the display
	display::xScrollService
	display::plotStrip

}

# display::xScroll
#
# Scrolls or the strip chart left or right or moves to a specified sample position depending on the input parameter (dir).  
proc display::xScroll {command args} {
	variable xStart
	variable xEnd
	variable xSpan

	#Determine if we are scrolling or moving
	switch $command {
		"scroll" {
			#Get the scroll distance from the input arguments
			set distance [lindex $args 0]
			#Calculate the new starting sample
			set temp [expr {$xStart+$distance}]
			#Make sure the sample number is positive
			if { $temp < 0} {
				set xStart 0
			} else {
				set xStart $temp
			}
			#Make sure we don't scroll past the available data
			if {$xStart >= [lindex [lindex $scope::stripData end-1] 1]} {
				set xStart [lindex [lindex $scope::stripData end-1] 1]
			}
			#Calculate the new end sample
			set xEnd [expr {$xStart+$xSpan}]
		} "moveto" {
			#Get the new sample position from the input arguments
			set position [lindex $args 0]
			#Calculate the new start and end samples from the moveto position
			#set xStart [expr {round([lindex [lindex $scope::stripData $scope::stripSample] 1]*$position)}]
			set xStart [expr {round([lindex [lindex $scope::stripData end-1] 1]*$position)}]
			set xEnd [expr {$xStart+$xSpan}]
		}
		
	}
	
	#Disable auto scaling
	set display::scrollMode disabled
	
	#Update the display
	display::xScrollService
	display::plotStrip
}

# display::xScrollService
#
# This procedure reconfigures the scroller widget to indicate the displayed position in the data
proc display::xScrollService {} {
	variable xStart
	variable xEnd

	#Update the x-axis labels
	display::xAxisLabels

	set lastSampleTime [lindex [scope::getStripSample [expr {$scope::stripSample-1}]] 1]
	
	#Update the time cursors
	cursor::measureTimeCursors
	
	#Make sure we have samples to display
	if {$scope::stripSample==0} {return}

	#Make sure we have enough samples to fill the screen
	if {($xStart==0)&&($lastSampleTime < $xEnd)} {
		[getDisplayPath].xScroll.scroller set 0.0 1.0
	} else {
		#Determine how much of the data is being displayed
		set start [expr {$xStart*1.0/$lastSampleTime}]
		set end [expr {$xEnd*1.0/$lastSampleTime}]
		
		#Adjust the scroll bar
		[getDisplayPath].xScroll.scroller set $start $end
	}

	display::updateMarker 0
}

# display::autoScaleX
#
# This procedure automatically scales the x-axis to display all of the available data
proc display::autoScaleX {} {
	variable xStart
	variable xEnd
	variable xSpan

	if {$display::scrollMode=="autoScale"} {
		set xStart 0
		
		#Get the index of the last sample
		set max [lindex [scope::getStripSample [expr {$scope::stripSample-1}]] 1]
		if {$max<10} {
			set xEnd 10
		} else {
			set xEnd $max
		}
		
		#Set the span to the full range
		set xSpan [expr {$xEnd-$xStart}]
		
		#Update the scroll bar
		xScrollService
	}
}

# display::autoScrollX
#
# This procedure automatically scrolls so that the newest samples are always visible.  The scrolling
# is performed while maintaining the zoom level of the x-axis.
proc display::autoScrollX {} {
	variable xStart
	variable xEnd
	variable xSpan
	
	
	if {$display::scrollMode=="autoScroll"} {
		
		#Determine the last (newest) sample
		set lastSampleTime [lindex [scope::getStripSample [expr {$scope::stripSample-1}]] 1]
		if {$lastSampleTime < 10} {
			set xEnd 10
		} else {
			set xEnd $lastSampleTime
		}
		
		#Adjust the starting point so that the newest sample is the last sample displayed
		set xStart [expr {$xEnd-$xSpan}]
		if {$xStart < 0} {
			set xStart 0
		}

		#Update the scroll bar
		xScrollService
	}
}

# display::createGridPopup
#
# Creates a pop-up menu for adjusting the scope grid display
proc display::createGridPopup {displayPath mode} {

	#Create a sub-menu for grid options
	menu $displayPath.popup.gridMenu -tearoff 0
	
	#Strip chart controls
	if {$mode=="strip"} {
	
		#Scaling/Scrolling Controls
		$displayPath.popup add separator
		$displayPath.popup add checkbutton	\
			-label "Auto Scroll"	\
			-variable display::autoScrollEnable	\
			-command {
				set display::autoScaleEnable 0
				display::updateScrollMode
			}
		$displayPath.popup add checkbutton	\
			-label "Auto Scale"	\
			-variable display::autoScaleEnable	\
			-command {
				set display::autoScrollEnable 0
				display::updateScrollMode
			}
		$displayPath.popup add command	\
			-label "Set X-Axis Max/Min"	\
			-command {display::showGraphSettings; focus .graphSettings.x}
	}
	
	#Grid-related controls
	$displayPath.popup add separator
	$displayPath.popup add cascade	\
		-menu $displayPath.popup.gridMenu	\
		-label "Grid"
	$displayPath.popup.gridMenu add check	\
		-label "X-Axis Grid"	\
		-variable display::xGridEnabled	\
		-command display::drawAxes
	$displayPath.popup.gridMenu add check	\
		-label "Y-Axis Grid"		\
		-variable display::yGridEnabled	\
		-command display::drawAxes
	$displayPath.popup.gridMenu add separator
	$displayPath.popup.gridMenu add command	\
		-label "Color Options"	\
		-command display::showColorOptions
	#$displayPath.popup.gridMenu add command	\
	#	-label "X-Axis Color..."	\
	#	-command {
	#		set newColor [tk_chooseColor]
	#		if {$newColor != ""} {
	#			set display::xGridColor $newColor
	#			display::drawAxes
	#		}
	#	}
	#$displayPath.popup.gridMenu add command	\
	#	-label "Y-Axis Color..."	\
	#	-command {
	#		set newColor [tk_chooseColor]
	#		if {$newColor != ""} {
	#			set display::yGridColor $newColor
	#			display::drawAxes
	#		}
	#	}
}

# display::updateScrollMode
#
# Updates the display::scrollMode variable whenever the user changes scrolling modes
proc display::updateScrollMode {} {

	if {$display::autoScaleEnable} {
		set display::scrollMode autoScale
	} elseif {$display::autoScrollEnable} {
		set display::scrollMode autoScroll
	} else {
		set display::scrollMode disabled
	}

}

# display::showGraphSettings
#
# Creates a window which holds controls for adjusting the strip chart display settings.
proc display::showGraphSettings {} {

	if {![winfo exists .graphSettings]} {
		
		toplevel .graphSettings
		wm title .graphSettings "Strip Chart Graph Settings"
		
		#Frame to hold x-axis settings
		frame .graphSettings.x	\
			-relief groove	\
			-borderwidth 2
			
		#X-Axis Limit Settings
		frame .graphSettings.x.limits	\
			-relief groove	\
			-borderwidth 1
		label .graphSettings.x.limits.title	\
			-text "X Axis Limits"	\
			-font {-weight bold -size -12}
		label .graphSettings.x.limits.startTitle	\
			-text "Start:"
		entry .graphSettings.x.limits.start	\
			-validate focusout	\
			-validatecommand {display::checkGraphLimit x start}	\
			-width 10	\
			-justify center
		bind .graphSettings.x.limits.start <KeyPress-Return> {set display::scrollMode disabled;.graphSettings.x.limits.start validate}
		.graphSettings.x.limits.start insert 0 $display::xStart
		label .graphSettings.x.limits.endTitle	\
			-text "End:"
		entry .graphSettings.x.limits.end	\
			-validate focusout	\
			-validatecommand {display::checkGraphLimit x end}	\
			-width 10	\
			-justify center
		bind .graphSettings.x.limits.end <KeyPress-Return> {set display::scrollMode disabled;.graphSettings.x.limits.end validate}
		.graphSettings.x.limits.end insert 0 $display::xEnd
		checkbutton .graphSettings.x.limits.autoscale	\
			-text "Auto Scale"	\
			-variable display::autoScaleEnable	\
			-command {
				set display::autoScrollEnable 0
				display::updateScrollMode
			}
		checkbutton .graphSettings.x.limits.autoscroll	\
			-text "Auto Scroll"	\
			-variable display::autoScrollEnable	\
			-command {
				set display::autoScaleEnable 0
				display::updateScrollMode
			}
		grid .graphSettings.x.limits.title -row 0 -column 0 -columnspan 2
		grid .graphSettings.x.limits.startTitle -row 1 -column 0
		grid .graphSettings.x.limits.start -row 1 -column 1
		grid .graphSettings.x.limits.endTitle -row 2 -column 0
		grid .graphSettings.x.limits.end -row 2 -column 1
		grid .graphSettings.x.limits.autoscale -row 3 -column 0 -columnspan 2
		grid .graphSettings.x.limits.autoscroll -row 4 -column 0 -columnspan 2
		
		#Place x-axis settings frames
		grid .graphSettings.x.limits -row 0 -column 0
		
		#Close button
		button .graphSettings.close	\
			-text "Close"	\
			-command {destroy .graphSettings}
		
		#Place main settings frames
		grid .graphSettings.x -row 0 -column 0
		grid .graphSettings.close -row 1 -column 0 -sticky we
		
	} else {
		#Window already exists, bring it up
		wm deiconify .graphSettings
		raise .graphSettings
		focus .graphSettings
	}

}

# display::checkGraphLimit
#
# This is a helper procedure which checks values entered by the user against
# limits for the software/hardware
proc display::checkGraphLimit {axis pos} {

	if {$axis=="x"} {
		if {$pos=="end"} {
			#Get the value from the entry widget
			set newValue [.graphSettings.x.limits.end get]
			#Make sure the value is an integer
			if {[string is integer -strict $newValue]!=1} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "Value must be an integer."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			if {$newValue<=$display::xStart} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "X Axis end value must be greater than the start value."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			if {$newValue>100E6} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "X Axis value is too large."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			set display::xEnd $newValue
			display::xZoom update
			return 1
		} elseif {$pos=="start"} {
			#Get the value from the entry widget
			set newValue [.graphSettings.x.limits.start get]
			#Make sure the value is an integer
			if {[string is integer -strict $newValue]!=1} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "Value must be an integer."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			if {$newValue<0} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "X Axis start value must be positive."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			if {$newValue>=$display::xEnd} {
				tk_messageBox	\
					-default ok	\
					-icon error	\
					-message "X Axis start value must be smaller than the end value."	\
					-parent .graphSettings	\
					-title "Value Error"	\
					-type ok
				return 0
			}
			set display::xStart $newValue
			display::xZoom update
			return 1
		} else {
			return 0
		}
	} else {
		return 0
	}

}

# display::updateMarker
#
# This procedure updates the data marker in strip chart mode.  The boolean "snap" parameter
# determines if this routine snaps the displayed data to the marker.
proc display::updateMarker {snap} {

	#Remove the old marker
	set displayPath "[display::getDisplayPath].graph"
	$displayPath delete dataMarker

	#Make sure a marker is defined
	if {$recorder::sampleMarker==""} {return}
	
	#Make sure the marker is within our data set
	if {$recorder::sampleMarker>$scope::stripSample} {return}
	
	#X-Position of the sample
	set xT [lindex [scope::getStripSample $recorder::sampleMarker] 1]
	
	#Turn off auto-scrolling if we are snapping
	if {$snap} {
		set display::scrollMode disabled
	}
	
	#See if we need to snap the display to the marker position
	if {$snap} {
		if {($xT > $display::xEnd)||($xT < $display::xStart)} {
			set xSpan [expr {$display::xEnd-$display::xStart}]
			set display::xStart [expr {$xT-$xSpan/2.0}]
			set display::xEnd [expr {$display::xStart+$xSpan}]
			display::plotStrip
		}
	}
	
	#X screen coordinate of the sample
	set x [display::graphPlotX $xT]
	
	#Y-Coordinate of the sample
	set displayHeight [expr {$display::yAxisEnd-$display::yAxisStart}]
	set datum [scope::getStripSample $recorder::sampleMarker]
	set yA [lindex $datum 2]
	set yB [lindex $datum 3]
	set yA [expr {$displayHeight/2.0+$display::yAxisStart+$displayHeight*($yA/(10*[lindex $vertical::verticalValues $vertical::verticalIndexA]))}]
	set yB [expr {$displayHeight/2.0+$display::yAxisStart+$displayHeight*($yB/(10*[lindex $vertical::verticalValues $vertical::verticalIndexB]))}]
	
	#Draw the marker for channel A
	$displayPath create line	\
		$x [expr {$yA-2}]	\
		$x [expr {$yA-22}]	\
		-tag dataMarker		\
		-fill $display::channelAColor	\
		-width 2
	$displayPath create polygon	\
		$x [expr {$yA-2}]	\
		[expr {$x+3}] [expr {$yA-8}]	\
		[expr {$x-3}] [expr {$yA-8}]	\
		-tag dataMarker	\
		-fill $display::channelAColor	\
		-width 2
	$displayPath create oval	\
		[expr {$x-2}] [expr {$yA-2}]	\
		[expr {$x+3}] [expr {$yA+3}]	\
		-fill $display::channelAColor	\
		-outline $display::channelAColor	\
		-tag dataMarker
	
	#Draw the marker for channel B
	$displayPath create line	\
		$x [expr {$yB-2}]	\
		$x [expr {$yB-22}]	\
		-tag dataMarker		\
		-fill $display::channelBColor	\
		-width 2
	$displayPath create polygon	\
		$x [expr {$yB-2}]	\
		[expr {$x+3}] [expr {$yB-8}]	\
		[expr {$x-3}] [expr {$yB-8}]	\
		-tag dataMarker	\
		-fill $display::channelBColor	\
		-width 2
	$displayPath create oval	\
		[expr {$x-2}] [expr {$yB-2}]	\
		[expr {$x+3}] [expr {$yB+3}]	\
		-fill $display::channelBColor	\
		-outline $display::channelBColor	\
		-tag dataMarker
}

# display::toggleXYMode
#
# This procedure is called when the user changes into or out of XY display mode,
# It cleans up the display if XY is disabled.
proc display::toggleXYMode {} {

	if {!$display::xyEnable} {
		set displayPath [display::getDisplayPath]
		$displayPath.display delete xyLabel
		$displayPath.display delete xyPlotTag
	}
}

# display::plotXY
#
# This procedure creates the X-Y plot on the scope display using the data in the scope::scopeData array.
proc display::plotXY {} {

	#Make sure XY mode is enabled
	if {!$display::xyEnable} {return}
	
	#Get the widget path for the scope display
	set displayPath [display::getDisplayPath]
	$displayPath.display delete xyPlotTag
	
	#Get the current scope data
	set dataA [lindex $scope::scopeData 0]
	set dataB [lindex $scope::scopeData 1]
	
	#X-Data created from channel A
	set xData {}
	foreach datumA $dataA {
		set actualVoltage  [vertical::convertSampleVoltage $datumA A]
		set numDiv [expr {$actualVoltage/[vertical::getBoxSize A]}]
		set screenx [expr {$display::xAxisStart+$numDiv*(($display::xAxisEnd-$display::xAxisStart)/10.0)+(($display::xAxisEnd-$display::xAxisStart)/2.0)}]
		lappend xData $screenx
	}
	
	#Y-Data created from channel B
	set yData {}
	foreach datumB $dataB {
		set actualVoltage [vertical::convertSampleVoltage $datumB B]
		set numDiv [expr {$actualVoltage/[vertical::getBoxSize B]}]
		set screeny [expr {$display::yAxisStart+$numDiv*(($display::yAxisEnd-$display::yAxisStart)/-10.0)+(($display::yAxisEnd-$display::yAxisStart)/2.0)}]
		lappend yData $screeny
	}
	
	#Build the X-Y trace data array
	set plotData {}
	foreach xDatum $xData yDatum $yData {
		lappend plotData $xDatum $yDatum
	}
	
	#Draw the X-Y trace
	$displayPath.display create line	\
		$plotData		\
		-tag xyPlotTag	\
		-fill black

}

proc display::showColorOptions {} {
	#Check to see if the color preferences dialog is already open
	if {[winfo exists .color]} {
		raise .color
		focus .color
		return
	}
	
	#Create the color preferences window
	toplevel .color
	wm resizable .color 0 0
	wm title .color "Color Preferences"
	
	labelframe .color.colors	\
		-text "Oscilloscope Display"	\
		-borderwidth 2		\
		-padx 10	\
		-pady 10
	
	label .color.colors.colorLabel -text "Color"
	
	#Scope Display Background
	label .color.colors.backgroundLabel -text "Scope Background"
	button .color.colors.backgroundButton	\
		-background $display::backgroundColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::backgroundColor $newColor
				[display::getDisplayPath].display configure -background $newColor
				.color.colors.backgroundButton configure -background $newColor
			}
		}
		
	#Scope X Grid
	label .color.colors.xGridLabel -text "Scope X Grid"
	button .color.colors.xGridButton	\
		-background $display::xGridColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::xGridColor $newColor
				display::drawAxes
				.color.colors.xGridButton configure -background $newColor
			}
		}
		
	#Scope Y Grid
	label .color.colors.yGridLabel -text "Scope Y Grid"
	button .color.colors.yGridButton	\
		-background $display::yGridColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::yGridColor $newColor
				display::drawAxes
				.color.colors.yGridButton configure -background $newColor
			}
		}
	
	#Scope Border
	label .color.colors.borderLabel -text "Scope Border"
	button .color.colors.borderButton	\
		-background $display::axisColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::axisColor $newColor
				display::drawAxes
				.color.colors.borderButton configure -background $newColor
			}
		}
		
	grid .color.colors.colorLabel -row 0 -column 1
	
	grid .color.colors.backgroundLabel -row 1 -column 0
	grid .color.colors.backgroundButton -row 1 -column 1
	grid .color.colors.xGridLabel -row 2 -column 0
	grid .color.colors.xGridButton -row 2 -column 1
	grid .color.colors.yGridLabel -row 3 -column 0
	grid .color.colors.yGridButton -row 3 -column 1
	grid .color.colors.borderLabel -row 4 -column 0
	grid .color.colors.borderButton -row 4 -column 1
	
	#Oscilloscope Trace Colors
	labelframe .color.traces	\
		-text "Oscilloscope Traces"	\
		-borderwidth 2		\
		-padx 10	\
		-pady 10
		
	label .color.traces.colorLabel -text "Color"
	
	#Channel A
	label .color.traces.aLabel -text "Channel A"
	button .color.traces.aButton	\
		-background $display::channelAColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::channelAColor $newColor
				.color.traces.aButton configure -background $newColor
				cursor::reDrawChAGndCursor
				cursor::toggleChACursor; cursor::toggleChACursor
			}
		}
		
	#Channel B
	label .color.traces.bLabel -text "Channel B"
	button .color.traces.bButton	\
		-background $display::channelBColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set display::channelBColor $newColor
				.color.traces.bButton configure -background $newColor
				cursor::reDrawChBGndCursor
				cursor::toggleChBCursor; cursor::toggleChBCursor
			}
		}
	
	grid .color.traces.colorLabel -row 0 -column 1
	
	grid .color.traces.aLabel -row 1 -column 0 -padx 14
	grid .color.traces.aButton -row 1 -column 1 -padx 15
	grid .color.traces.bLabel -row 2 -column 0
	grid .color.traces.bButton -row 2 -column 1

	#Cursor Colors
	labelframe .color.cursors	\
		-text "Cursors"	\
		-borderwidth 2		\
		-padx 10	\
		-pady 10
		
	label .color.cursors.colorLabel -text "Color"
	
	#Trigger Cursor
	label .color.cursors.trigLabel -text "Trigger Cursor"
	button .color.cursors.trigButton	\
		-background $cursor::trigColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set cursor::trigColor $newColor
				.color.cursors.trigButton configure -background $newColor
				cursor::reDrawTriggerCursor
			}
		}
		
	#Trigger Point Cursor
	label .color.cursors.timeLabel -text "Trigger Point Cursor"
	button .color.cursors.timeButton	\
		-background $cursor::timeColor	\
		-width 2	\
		-height 1	\
		-command {
			set newColor [tk_chooseColor]
			if {$newColor != ""} {
				set cursor::timeColor $newColor
				.color.cursors.timeButton configure -background $newColor
				cursor::reDrawXCursor
			}
		}
	
	grid .color.cursors.colorLabel -row 0 -column 1
	
	grid .color.cursors.trigLabel -row 1 -column 0
	grid .color.cursors.trigButton -row 1 -column 1
	grid .color.cursors.timeLabel -row 2 -column 0
	grid .color.cursors.timeButton -row 2 -column 1
	
	button .color.resetDefaults	\
		-text "Reset to Defaults"	\
		-command display::resetColorDefaults
	
	button .color.saveExit	\
		-text "Save and Close"	\
		-command {
			display::saveDisplaySettings
			destroy .color
		}
		
	grid .color.colors -row 0 -column 0 -sticky we
	grid .color.traces -row 1 -column 0 -sticky we
	grid .color.cursors -row 2 -column 0 -sticky we
	grid .color.resetDefaults -row 3 -column 0 -pady 5
	grid .color.saveExit -row 4 -column 0 -pady 5
	
}

proc display::saveDisplaySettings {} {

	set fileId [open color.cfg w]
	puts $fileId $display::backgroundColor
	puts $fileId $display::xGridColor
	puts $fileId $display::yGridColor
	puts $fileId $display::axisColor
	puts $fileId $display::channelAColor
	puts $fileId $display::channelBColor
	puts $fileId $cursor::trigColor
	puts $fileId $cursor::timeColor
	close $fileId

}

proc display::readColorSettings {} {

	#See if there are any saved preferences
	if [catch {open color.cfg r} fileId] {
		puts "No custom color preferences found."
	} else {
		#Background Color
		if {[gets $fileId line] >= 0} {
			set display::backgroundColor $line
			[display::getDisplayPath].display configure -background $line
		}
		#X Grid Color
		if {[gets $fileId line] >= 0} {
			set display::xGridColor $line
			display::drawAxes
		}
		#Y Grid Color
		if {[gets $fileId line] >= 0} {
			set display::yGridColor $line
			display::drawAxes
		}
		#Border Color
		if {[gets $fileId line] >= 0} {
			set display::axisColor $line
			display::drawAxes
		}
		#Trace Color A
		if {[gets $fileId line] >= 0} {
			set display::channelAColor $line
		}
		#Trace Color B
		if {[gets $fileId line] >= 0} {
			set display::channelBColor $line
		}
		#Trigger Cursor
		if {[gets $fileId line] >= 0} {
			set cursor::trigColor $line
		}
		#Trigger Point Cursor
		if {[gets $fileId line] >= 0} {
			set cursor::timeColor $line
		}
		puts "Custom color preferences found."
	}

}

proc display::resetColorDefaults {} {
	
	set display::backgroundColor white
	[display::getDisplayPath].display configure -background white
	.color.colors.backgroundButton configure -background white
	
	set display::xGridColor grey
	display::drawAxes
	.color.colors.xGridButton configure -background grey
	
	set display::yGridColor grey
	display::drawAxes
	.color.colors.yGridButton configure -background grey

	set display::axisColor black
	display::drawAxes
	.color.colors.borderButton configure -background black
	
	set display::channelAColor red
	.color.traces.aButton configure -background red
	cursor::reDrawChAGndCursor
	cursor::toggleChACursor; cursor::toggleChACursor

	set display::channelBColor blue
	.color.traces.bButton configure -background blue
	cursor::reDrawChBGndCursor
	cursor::toggleChBCursor; cursor::toggleChBCursor
	
	set cursor::trigColor green
	.color.cursors.trigButton configure -background green
	cursor::reDrawTriggerCursor
	
	set cursor::timeColor violet
	.color.cursors.timeButton configure -background violet
	cursor::reDrawXCursor

}
