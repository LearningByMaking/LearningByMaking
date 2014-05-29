#File: timebase.tcl
#Syscomp CGM-101 Graphic User Interface
#Main File

#JG
#Copyright 2012 Syscomp Electronic Design
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

namespace eval timebase {

set timebasePath .

set canvasSize 75

set baseSamplingRate 2.0E6
set samplesPerPixel 1.0
set sampleIncrement 1


set timebaseSetting 0.001
set validTimebases {	\
	{500E-9 0} \
	{1E-6 1}	\
	{2E-6 1}	\
	{5E-6 1}	\
	{10E-6 1}	\
	{20E-6 1}	\
	{50E-6 1}	\
	{100E-6 2} \
	{200E-6 3} \
	{500E-6 5} \
	{1E-3 6}	\
	{2E-3 7}	\
	{5E-3 8}	\
	{10E-3 9}	\
	{20E-3 A}	\
	{50E-3 B}	\
	{100E-3 C}	\
	{200E-3 D}	\
	{500E-3 E}	\
	{1 F}	\
	{2 G}	\
	{5 H}	\
	{10 I}	\
	{20 J}
	}
set timebaseIndex 10
set newTimebaseIndex $timebaseIndex
set samplingRates {
	2.0E6	\
	1.0E6	\
	500.0E3	\
	250.0E3	\
	125.0E3	\
	62.5E3
	}
	
set validSamplePeriods { 20 50 100 200 500 1000 2000 }
set samplePeriodIndex 3

#Images
set zoomInImage [image create photo -file "$::images/MagIn.gif"]
set zoomOutImage [image create photo -file "$::images/MagOut.gif"]
set recordButtonImage [image create photo -file "./Images/RecordButton.gif"]
set stopButtonImage [image create photo -file "./Images/StopButton.gif"]

set timebaseMode normal
set stripChartMode scan

set stripChartSamplePeriod 10

}

proc timebase::buildControls {timebasePath} {
	
	set timebase::timebasePath $timebasePath
	
	#Make the frame pretty
	$timebasePath configure -relief groove -borderwidth 2

	#Create a canvas to indicate the timebase settings
	canvas $timebasePath.display	\
		-width $timebase::canvasSize	\
		-height $timebase::canvasSize	\
		-background white
	#Draw a box
	$timebasePath.display create rectangle	\
		4 4	\
		 [expr {$timebase::canvasSize-1}]  [expr {$timebase::canvasSize-1}]	\
		 -dash {10 10} \
		 -fill ""	\
		 -outline black	\
		 -width 2
	
	timebase::updateIndicator

	#Button to zoom in timebase
	button $timebasePath.zoomIn	\
		-image $timebase::zoomInImage	\
		-command "timebase::adjustTimebase in"
		
	#Button to zoom out timebase
	button $timebasePath.zoomOut	\
		-image $timebase::zoomOutImage	\
		-command "timebase::adjustTimebase out"
	
	#Menu for timebase options
	menubutton $timebasePath.options	\
		-text "Options"	\
		-menu $timebasePath.options.optionsMenu	\
		-relief raised
	menu $timebasePath.options.optionsMenu -tearoff 0
	
	#Sampling mode options
	$timebasePath.options.optionsMenu add radiobutton	\
		-label "Sampling"	\
		-value normal	\
		-variable timebase::timebaseMode
	$timebasePath.options.optionsMenu add radiobutton	\
		-label "Scan"	\
		-value scan	\
		-variable timebase::stripChartMode	\
		-state disabled	\
		-command timebase::toggleStripChartMode
	$timebasePath.options.optionsMenu add radiobutton	\
		-label "Strip Chart"	\
		-value strip	\
		-variable timebase::stripChartMode	\
		-state disabled	\
		-command timebase::toggleStripChartMode
	$timebasePath.options.optionsMenu add separator
	#Command to reset strip chart
	$timebasePath.options.optionsMenu add command	\
		-label "Reset Strip Chart"	\
		-command scope::resetStripChart	\
		-state disabled
	$timebasePath.options.optionsMenu add separator
	#Strip Chart Auto Scoll/Scale Commands
	$timebasePath.options.optionsMenu add check	\
		-label "Auto Scroll"	\
		-variable display::autoScrollEnable	\
		-state disabled	\
		-command {
			set display::autoScaleEnable 0
			display::updateScrollMode
		}
	$timebasePath.options.optionsMenu add check	\
		-label "Auto Scale"	\
		-variable display::autoScaleEnable	\
		-state disabled	\
		-command {
			set display::autoScrollEnable 0
			display::updateScrollMode
		}
	$timebasePath.options.optionsMenu add radiobutton	\
		-label "Manual Scroll/Scale"	\
		-variable display::scrollMode	\
		-state disabled	\
		-command {
			set display::autoScrollEnable 0
			set display::autoScaleEnable 0
			display::updateScrollMode
		}
	
	#Frame for strip chart controls
	frame $timebasePath.stripControls	\
		-relief groove	\
		-borderwidth 1
		
	button $timebasePath.stripControls.go	\
		-image $timebase::recordButtonImage	\
		-command scope::startStripChart
	label $timebasePath.stripControls.goLabel	\
		-text "Start"
	
	button $timebasePath.stripControls.stop	\
		-image $timebase::stopButtonImage	\
		-command scope::stopStripChart
	label $timebasePath.stripControls.stopLabel	\
		-text "Stop"
		
	grid $timebasePath.stripControls.go -row 0 -column 0 -padx 5
	grid $timebasePath.stripControls.goLabel -row 1 -column 0
	grid $timebasePath.stripControls.stop -row 0 -column 1 -padx 5
	grid $timebasePath.stripControls.stopLabel -row 1 -column 1
	
	
	grid $timebasePath.display -row 1 -column 0 -columnspan 2
	grid $timebasePath.zoomIn -row 2 -column 0
	grid $timebasePath.zoomOut -row 2 -column 1
	grid $timebasePath.options -row 3 -column 0 -sticky we -columnspan 2
	
	
}

proc timebase::updateIndicator {} {
	variable timebasePath
	variable timebaseIndex
	variable newTimebaseIndex

	#Clear the Display
	$timebasePath.display delete timebase
	
	#Draw arrows for sampling and scan mode
	if {$timebase::timebaseMode != "strip"} {
		#Draw Arrows
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.75}]	\
			4 [expr {$timebase::canvasSize*0.75}]	\
			-width 2	\
			-arrow last	\
			-fill violet	\
			-tag timebase
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.75}]	\
			[expr {$timebase::canvasSize-1}] [expr {$timebase::canvasSize*0.75}] 	\
			-width 2	\
			-arrow last	\
			-fill violet	\
			-tag timebase
			
		#Get the current timebase setting
		set setting [lindex [lindex $timebase::validTimebases $newTimebaseIndex] 0]
		if {$timebaseIndex != $newTimebaseIndex} {
			set timebaseString "([timebase::formatTime $setting])"
		} else {
			set timebaseString "[timebase::formatTime $setting]"
		}
		
		#Update the setting
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.6}]	\
			-anchor center	\
			-text $timebaseString	\
			-fill violet	\
			-font {-weight bold -size -12}	\
			-tag timebase
	}
		
	#Update the timbase mode display
	if {$timebase::timebaseMode=="normal"} {
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.4}]	\
			[expr {$timebase::canvasSize*0.8}] [expr {$timebase::canvasSize*0.4}]	\
			-width 2	\
			-arrow last	\
			-fill grey	\
			-tag timebase
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.3}]	\
			-anchor center	\
			-text "SAMPLING"	\
			-fill black	\
			-font {-size -10}	\
			-tag timebase
	} elseif {$timebase::timebaseMode=="scan"} {
		$timebasePath.display create arc	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.7}]	\
			[expr {$timebase::canvasSize*0.8}] [expr {$timebase::canvasSize*0.1}]	\
			-width 2	\
			-outline grey	\
			-style arc	\
			-extent 180\
			-dash .	\
			-tag timebase
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize*0.202}] [expr {$timebase::canvasSize*0.39}]	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.40}]	\
			-width 2	\
			-fill grey	\
			-arrow last	\
			-tag timebase
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.4}]	\
			[expr {$timebase::canvasSize*0.8}] [expr {$timebase::canvasSize*0.4}]	\
			-width 2	\
			-fill grey	\
			-arrow last	\
			-tag timebase
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.3}]	\
			-anchor center	\
			-text "SCAN"	\
			-fill black	\
			-font {-size -10}	\
			-tag timebase
	} elseif {$timebase::timebaseMode=="strip"} {
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.4}]	\
			[expr {$timebase::canvasSize*0.8}] [expr {$timebase::canvasSize*0.4}]	\
			-width 2	\
			-arrow last	\
			-fill grey	\
			-dash .	\
			-tag timebase
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.3}]	\
			-anchor center	\
			-text "STRIP"	\
			-fill black	\
			-font {-size -10}	\
			-tag timebase
		set periodString "[timebase::formatTime [expr {$timebase::stripChartSamplePeriod/1000.0}]]"
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.6}]	\
			-anchor center	\
			-text $periodString	\
			-fill violet	\
			-font {-weight bold -size -12}	\
			-tag timebase
		$timebasePath.display create line	\
			[expr {$timebase::canvasSize*0.8}] [expr {$timebase::canvasSize*0.75}]	\
			[expr {$timebase::canvasSize*0.2}] [expr {$timebase::canvasSize*0.75}]	\
			-width 2	\
			-fill violet	\
			-tag timebase
		$timebasePath.display create text	\
			[expr {$timebase::canvasSize/2.0}] [expr {$timebase::canvasSize*0.85}]	\
			-anchor center	\
			-text "sample"	\
			-fill violet	\
			-font {-weight bold -size -12}	\
			-tag timebase
	}

	cursor::measureTimeCursors

}

proc timebase::formatTime {timeVal} {

	if {$timeVal < 1E-6} {
		set temp [format "%.0f" [expr {$timeVal*1.0/1E-9}]]
		return "$temp ns"
	} elseif {$timeVal < 1E-3} {
		set temp [format "%.0f" [expr {$timeVal*1.0/1E-6}]]
		return "$temp us"
	} elseif {$timeVal < 1} {
		set temp [format "%.0f" [expr {$timeVal*1.0/1E-3}]]
		return "$temp ms"
	} else {
		return "$timeVal s"
	}
}

proc timebase::adjustTimebase {dir} {
	variable timebaseIndex
	variable validTimebases
	variable newTimebaseIndex
	variable timebaseSetting

	#Circumvent timebase control for strip chart mode
	if {$timebase::timebaseMode == "strip"} {
		timebase::adjustStripSamplePeriod $dir
		return
	}

	switch $dir {
		"in" {
			if {$newTimebaseIndex==$timebaseIndex} {
				set newTimebaseIndex [expr {$timebaseIndex-1}]
			} else {
				set newTimebaseIndex [expr {$newTimebaseIndex-1}]
			}
		} "out" {
			if {$newTimebaseIndex==$timebaseIndex} {
				set newTimebaseIndex [expr {$timebaseIndex+1}]
			} else {
				set newTimebaseIndex [expr {$newTimebaseIndex+1}]
			}
		}
	}

	if {$newTimebaseIndex < 1} {
		set newTimebaseIndex 1
	}
	
	if {$newTimebaseIndex > [expr {[llength $validTimebases]-1}]} {
		set newTimebaseIndex [expr {[llength $validTimebases]-1}]
	}

	#if {$cursor::timeCursorsEnable} {
	#	cursor::measureTimeCursors
	#}
	
	#Settings have changed, make the display reflect the changes
	display::outOfDate
	
	set oldTimebase [lindex [lindex $validTimebases $timebaseIndex] 0]
	set newTimebase [lindex [lindex $validTimebases $newTimebaseIndex] 0]
	
	set timebaseIndex $newTimebaseIndex
	set timebaseSetting $newTimebase
	
	#Update the scope offsets based on the current sampling rate
	set sampleIndex [lindex [lindex $timebase::validTimebases $timebase::timebaseIndex] 1]
	puts "Sample index $sampleIndex"
	if {[string is integer $sampleIndex]} {
		if {$sampleIndex > 5} {
			set sampleIndex 0
		}
	} else {
		set sampleIndex 0
	}
	puts "Sample index $sampleIndex"
	set scope::offsetALow [lindex $scope::aLowOffsets $sampleIndex]
	set scope::offsetAHigh [lindex $scope::aHighOffsets $sampleIndex]
	set scope::offsetBLow [lindex $scope::bLowOffsets $sampleIndex]
	set scope::offsetBHigh [lindex $scope::bHighOffsets $sampleIndex]
	
	#Update the shift voltage setting to match the cursor positions
	vertical::updateShift A $cursor::chAGndVoltage
	vertical::updateShift B $cursor::chBGndVoltage
	
	
	if {( $newTimebase > 100E-3) && ($oldTimebase < 200E-3)} {
		#Switch to scan/strip mode
		set timebase::timebaseMode "scan"
		set timebase::stripChartMode "scan"
		#Disable the normal sampling menu item
		timebase::updateOptionsMenu
		#Remove the trigger level cursor
		[display::getDisplayPath].display delete trigLevelCursor
		#Remove the trigger point cursor
		[display::getDisplayPath].display delete timePosCursor
		#Disable the trigger controls
		$trigger::triggerPath.manualTrigger configure -state disabled
		$trigger::triggerPath.mode configure -state disabled
		$trigger::triggerPath.singleShotReset configure -state disabled
		$trigger::triggerPath.options configure -state disabled
		
		scope::startStripChart
	}
	
	if {($newTimebase < 200E-3) && ($oldTimebase > 100E-3)} {
		#We were in strip chart or scan mode, disable it
		scope::stopStripChart
		#Update the timebase mode to normal sampling
		set timebase::timebaseMode normal
		set timebase::stripChartMode scan
		#Update the options menu
		timebase::updateOptionsMenu
		#Put the display back into normal mode
		display::setMode normal
		#Restore the trigger level cursor
		cursor::reDrawTriggerCursor
		#Restore the trigger point cursor
		cursor::reDrawXCursor
		#Update the trigger controls
		trigger::selectTriggerMode
		#Enable trigger controls
		$trigger::triggerPath.manualTrigger configure -state normal
		$trigger::triggerPath.mode configure -state normal
		if {$trigger::triggerMode=="Single-Shot"} {
			$trigger::triggerPath.singleShotReset configure -state normal
		}
		$trigger::triggerPath.options configure -state normal
		#Remove the start/stop controls
		grid forget $timebase::timebasePath.stripControls

		#Clear the status bar
		[display::getDisplayPath].statusBar configure -text ""

		#Start sampling
		display::clearDisplay
		scope::acquireWaveform
	}
	
	if {$timebase::timebaseMode=="normal"} {
		#Update the auto trigger period
		set autoPeriod [expr {100*[lindex [lindex $timebase::validTimebases $timebase::timebaseIndex] 0]}]
		trigger::updateAutoTriggerPeriod $autoPeriod
		scope::acquireWaveform
	} else {
		scope::resetStripChart
		timebase::updateStripSamplePeriod [timebase::getPrescaler]
	}
	
	#Update the indicator
	timebase::updateIndicator

	
}

proc timebase::updateOptionsMenu {} {

	set timebasePath $timebase::timebasePath

	if {$timebase::timebaseMode=="normal"} {
		#Enable the normal sampling menu item
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Sampling"] -state normal
		#Disable the strip chart sampling mode radio buttons
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Scan"] -state disabled
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Strip Chart"] -state disabled
		#Disable the reset strip chart button
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Reset Strip Chart"] -state disabled
		#Disable the scrolling buttons
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scroll"] -state disabled
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scale"] -state disabled
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Manual Scroll/Scale"] -state disabled
	} else {
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Sampling"] -state disabled
		#Enable the strip chart sampling mode radio buttons
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Scan"] -state normal
		$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Strip Chart"] -state normal
		if {$timebase::stripChartMode=="strip"} {
			#Enable the reset strip chart button
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Reset Strip Chart"] -state normal
			#Enable the scrolling buttons
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scroll"] -state normal
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scale"] -state normal
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Manual Scroll/Scale"] -state normal
		} else {
			#Enable the reset strip chart button
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Reset Strip Chart"] -state disabled
			#Enable the scrolling buttons
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scroll"] -state disabled
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Auto Scale"] -state disabled
			$timebasePath.options.optionsMenu entryconfigure [$timebasePath.options.optionsMenu index "Manual Scroll/Scale"] -state disabled
		}
	}

}

proc timebase::adjustStripSamplePeriod {dir} {
	variable samplePeriodIndex
	variable validSamplePeriods

	if {($scope::stripChartEnabled)&&($dir!="update")} {
		set answer [tk_messageBox	\
			-default no	\
			-icon warning	\
			-message "Warning: Changing the sample period will reset the strip chart recorder"	\
			-detail "Are you sure?"	\
			-parent .	\
			-title "Change Sample Rate"	\
			-type yesno]
		if {$answer!="yes"} {return}
	}

	switch $dir {
		"in" {
			set samplePeriodIndex [expr {$samplePeriodIndex-1}]
		} "out" {
			incr samplePeriodIndex
		}
	}
	
	if {$samplePeriodIndex < 0} {
		set samplePeriodIndex 0
	}
	
	if {$samplePeriodIndex > [expr {[llength $validSamplePeriods]-1}]} {
		set samplePeriodIndex [expr {[llength $validSamplePeriods]-1}]
	}
	
	#Update the sample period
	set timebase::stripChartSamplePeriod [lindex $timebase::validSamplePeriods $timebase::samplePeriodIndex]
	
	#Reset strip chart hardware to clear the buffer
	scope::stopStripChart
	scope::resetStripChart
	
	#Update the indicator
	timebase::updateIndicator
	
	#Start a new series of captures if we are in scan mode
	if {$timebase::stripChartMode == "scan"} {
		scope::startStripChart
	}

}

proc timebase::updateTimebase {} {
	variable timebaseSetting
	variable timebaseIndex
	variable validTimebases
	variable newTimebaseIndex
	
	set timebaseIndex $newTimebaseIndex
	set temp [lindex $validTimebases $timebaseIndex]
	set timebaseSetting [lindex $temp 0]
	set samplingCode [lindex $temp 1]
	sendCommand "B$samplingCode"
	
	#updateSampling
	
}

proc timebase::getSamplingRate {} {
	variable timebaseIndex
	variable validTimebases

	switch [timebase::getPrescaler] {
		"0" {return 2.0E6}
		"1" {return 1.0E6}
		"2" {return 500.0E3}
		"3" {return 250.0E3}
		"4" {return 125.0E3}
		"5" {return 62.5E3}
		"6" {return 51200.0}
		"7" {return 25600.0}
		"8" {return 10240.0}
		"9" {return 5120.0}
		"A" {return 2560.0}
		"B" {return 1024.0}
		"C" {return 512.0}
		"D" {return 50.0}
		"E" {return 20.0}
		"F" {return 10.0}
		"G" {return 5.0}
		"H" {return 2.0}
		"I" {return 1.0}
		"J" {return 0.5}
		default {return "?"}
	}

}

proc timebase::getPrescaler {} {
	variable timebaseIndex
	variable validTimebases

	#Get the current timebase setting
	set temp [lindex $validTimebases $timebaseIndex]
	return [lindex $temp 1]

}


proc timebase::getSamplingPeriod {} {

	return [expr {1.0/[getSamplingRate]}]
	
}

proc timebase::toggleStripChartMode {} {

	if {$timebase::stripChartMode == "strip"} {
		display::setMode strip
		set timebase::timebaseMode strip
		#Get the current strip chart sample period
		set timebase::stripChartSamplePeriod [lindex $timebase::validSamplePeriods $timebase::samplePeriodIndex]
		timebase::updateStripSamplePeriod [timebase::getPrescaler]
		#Display the x-axis labels
		display::xAxisLabels
		#Show the data table
		recorder::buildRecorder
		#Show the start/stop controls
		grid $timebase::timebasePath.stripControls -row 4 -column 0 -columnspan 2 -sticky we
		#Update the status bar
		[display::getDisplayPath].statusBar configure -text "Strip Chart Mode"
	} else {
		#Switch back to sampling mode
		display::setMode scan
		set timebase::timebaseMode scan
		#Remove the data table
		destroy .recorder
		#Hide the start/stop controls
		grid forget $timebase::timebasePath.stripControls
		#Update the status bar
		[display::getDisplayPath].statusBar configure -text "Scan Mode"
		#Start sampling
		scope::startStripChart
		
	}
	#Make sure the timebase settings are correct
	timebase::adjustTimebase update
	
	timebase::updateOptionsMenu
	
	scope::resetStripChart
	
	timebase::updateIndicator

}

proc timebase::updateStripSamplePeriod {prescaler} {

	sendCommand "B$prescaler"
	
	
}