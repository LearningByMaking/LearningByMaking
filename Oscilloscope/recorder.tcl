#File: recorder.tcl
#Syscomp DSO-201 Graphic User Interface

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

namespace eval recorder {

set autoScroll 1

set bufferLevel 0
set bufferPercent 0

set tableStartIndex 0
set tableEndIndex 9
set sampleMarker ""

set streamEnable 0

}

proc recorder::buildRecorder {} {

	#Check to see if the recorder window is already open
	if {[winfo exists .recorder]} {
		raise .recorder
		focus .recorder
		return
	}

	#Create a new window for the data table
	toplevel .recorder
	wm title .recorder "Strip Chart Data"
	wm resizable .recorder 0 0
	wm protocol .recorder WM_DELETE_WINDOW {wm iconify .recorder}
	
	#Menu Bar
	frame .recorder.menubar -relief flat -borderwidth 1
	#Data Menu
	menubutton .recorder.menubar.data	\
		-text "Data"	\
		-menu .recorder.menubar.dataMenu
	menu .recorder.menubar.dataMenu	 -tearoff 0
	.recorder.menubar.dataMenu add command	\
		-label "Save Strip Chart Data"	\
		-command recorder::exportStripChartData
	#.recorder.menubar.dataMenu add command	\
	#	-label "Load Strip Chart Data"		\
	#	-state disabled
	#View Menu
	menubutton .recorder.menubar.view	\
		-text "View"	\
		-menu .recorder.menubar.viewMenu
	menu .recorder.menubar.viewMenu -tearoff 0
	.recorder.menubar.viewMenu add check	\
		-label "Auto Scroll Table"	\
		-variable recorder::autoScroll
	.recorder.menubar.viewMenu add command	\
		-label "Hide Data Table"	\
		-command {wm iconify .recorder}
	
	grid .recorder.menubar.data -row 0 -column 0 -sticky w
	grid .recorder.menubar.view -row 0 -column 1 -sticky w
	
	#Frame for table widget
	frame .recorder.dataTable	\
		-relief groove	\
		-borderwidth 1
		
	#Table to store samples
	table .recorder.dataTable.header	\
		-rows 1	\
		-cols 4	\
		-height 1	\
		-width 4	\
		-colwidth 20	\
		-resizeborders none	\
		-variable recorder::tableHeaders	\
		-state disabled	\
		-selecttype row	
	array set recorder::tableHeaders [list "0,0" "Sample" "0,1" "Time" "0,2" "Channel A" "0,3" "Channel B"]
	table .recorder.dataTable.table	\
		-rows 10	\
		-cols 4	\
		-height 10	\
		-width 4	\
		-colwidth 20	\
		-xscrollcommand [list .recorder.dataTable.xScroll set]	\
		-resizeborders none	\
		-variable recorder::dataTable	\
		-state disabled	\
		-selecttype row	\
		-browsecommand {recorder::highlightSample %r}
		
	scrollbar .recorder.dataTable.xScroll	\
		-command {.recorder.dataTable.table xview}	\
		-orient horizontal
	scrollbar .recorder.dataTable.yScroll	\
		-command {recorder::tableScroll}
	
	grid .recorder.dataTable.header -row 0 -column 0 -sticky we
	grid .recorder.dataTable.table -row 1 -column 0 -sticky we
	grid .recorder.dataTable.xScroll -row 2 -column 0 -sticky we
	grid columnconfig .recorder.dataTable.xScroll 1 -weight 1
	grid .recorder.dataTable.yScroll -row 1 -column 1 -sticky ns
	grid rowconfig .recorder.dataTable.yScroll 1 -weight 1
	
	#Controls for file recording
	frame .recorder.recording	\
		-relief groove	\
		-borderwidth 2
		
	checkbutton .recorder.recording.streamEnable	\
		-text "Stream Strip Chart Data to Disk"	\
		-variable recorder::streamEnable
		
	label .recorder.recording.streamFile	\
		-text  $scope::stripDataFile		\
		-relief sunken	\
		-width 80
		
	button .recorder.recording.selectFile	\
		-text "..."	\
		-command recorder::selectStripStreamFile
		
	grid .recorder.recording.streamEnable -row 0 -column 0 -columnspan 2
	grid .recorder.recording.streamFile -row 1 -column 0
	grid .recorder.recording.selectFile -row 1 -column 1
	
	#Place recorder widgets
	grid .recorder.menubar -row 0 -column 0 -sticky we
	grid .recorder.dataTable -row 1 -column 0
	grid .recorder.recording -row 2 -column 0 -sticky we

}

proc recorder::highlightSample {rowNumber} {
	variable sampleMarker
	
	set highlightedSample [expr {$rowNumber+$recorder::tableStartIndex}]
	
	if {$highlightedSample >= $scope::stripSample} {
		return
	}

	set recorder::autoScroll 0

	set sampleMarker $highlightedSample
	
	display::updateMarker 1

}

proc recorder::updateBufferIndicator {} {
	variable bufferLevel
	variable bufferPercent
	
	set bufferPercent [expr {$bufferLevel/1023.0*100}]
	
}

proc recorder::updateDataTable {} {
	variable tableStartIndex
	variable tableEndIndex

	#Populate the data table
	array unset recorder::dataTable
	for {set i 0} {$i < 10} {incr i} {
		#set dataA [lindex [lindex $scope::stripData [expr {$tableStartIndex+$i}]] 2]
		#set dataB [lindex [lindex $scope::stripData [expr {$tableStartIndex+$i}]] 3]
		set datum [scope::getStripSample [expr {$tableStartIndex+$i}]]
		set dataA [lindex $datum 2]
		set dataB [lindex $datum 3]
		if {($dataA=="")||($dataB=="")} {
			break
		}
		array set recorder::dataTable [list "$i,0" [expr {$tableStartIndex+$i}] "$i,1" [format "%.2f"  [expr {$timebase::stripChartSamplePeriod*1E-3*($tableStartIndex+$i)}]] "$i,2" [format "%.5f" $dataA] "$i,3" [format "%.5f" $dataB]]
	}
	
	recorder::tableScrollerService
}

proc recorder::tableScroll {command args} {
	variable tableStartIndex
	variable tableEndIndex
	
	switch $command {
		"scroll" {
			set distance [lindex $args 0]
			set tableStartIndex [expr {$tableStartIndex+$distance}]
			if {$tableStartIndex<0} {
				set $tableStartIndex 0
				return
			}
			set tableEndIndex [expr {$tableEndIndex+$distance}]
			if {$tableEndIndex > $scope::stripSample} {
				set tableEndIndex [expr {$tableEndIndex-$distance}]
				set tableStartIndex [expr {$tableStartIndex-$distance}]
				return
			}
		} "moveto" {
			set position [lindex $args 0]
			set tableStartIndex [expr {round($scope::stripSample*$position)}]
			set tableEndIndex [expr {$tableStartIndex+9}]
		}
		
	}
	#Disable auto scroll because the user is doing something
	set recorder::autoScroll 0
	#Remove any selected rows because things are about to change
	.recorder.dataTable.table selection clear all
	recorder::updateDataTable
}

proc recorder::tableScrollerService {} {
	variable tableStartIndex
	variable tableEndIndex

	if {($tableStartIndex==1)&&($scope::stripSample<$tableEndIndex)} {
		#Less than ten rows of data
		.recorder.dataTable.yScroll set 0.0 1.0
	} else {
		#Determine how much data is being displayed
		set start [expr {$tableStartIndex*1.0/$scope::stripSample}]
		set end [expr {$tableEndIndex*1.0/$scope::stripSample}]
		.recorder.dataTable.yScroll set $start $end
	}

}

proc recorder::selectStripStreamFile {} {

	set newFile [tk_getSaveFile	\
		-defaultextension "dat"	\
		-filetypes {{{Data Files} {.dat}}}	\
		-parent .recorder	\
		-title "Select Stream File"]
		
	if {$newFile == ""} {
		return
	}
	
	set scope::stripDataFile $newFile
	.recorder.recording.streamFile configure -text $newFile

}

proc recorder::exportStripChartData {} {

	set newFile [tk_getSaveFile	\
		-defaultextension "dat"	\
		-filetypes {{{Data Files} {.dat}}}	\
		-parent .recorder	\
		-title "Select File"]

	#Make sure a file was selected
	if {$newFile==""} {return}

	#Get a copy of the strip chart data
	set exportData $scope::stripData

	set fileHandle [open $newFile w+]
	foreach datum $exportData {
		puts $fileHandle $datum
	}
	close $fileHandle
	
	tk_messageBox	\
		-icon info	\
		-message "Data exported successfully!"	\
		-parent .recorder	\
		-title "File Save Complete"	\
		-type ok


}