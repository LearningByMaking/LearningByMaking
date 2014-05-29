#File: main.tcl
#Syscomp CircuitGear Mini Graphic User Interface
#JG

set softwareVersion "1.4"

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

#Procedure Index - main.tcl
#	showAbout
#	initializeCGR
#	showManual
#	showChangeLog

#Non-volatile addresses for saving parameters to the device (DO NOT CHANGE THESE, EVER)
set nvmAddressOffsets 0
set nvmAddressVertical 128

#Folder location for GUI Images
set images "./Images"

#Critical Packages
#Img package required for screen captures
package require Img
#BWidget package used for comboboxes
package require BWidget
#TKtable package used for table widgets
package require Tktable

#Status Indicator
for {set i 0} {$i < 15} {incr i} {
	set statusImage($i) [image create photo -file "$images/Connection$i.png"]
}
set statusState 0


#Debug level for printing messages to the console
set debugLevel 1

#Operating Mode
set opMode "CircuitGear"

#Figure out which operating system we're running on
set osType $tcl_platform(platform)
if {$osType == "unix"} {
	if {[exec uname] == "Darwin"} {set osType "Darwin"}
}

#---=== Core Includes ===----
source usbSerial.tcl
source scope.tcl
source dialog.tcl
source display.tcl
source cursors.tcl
source vertical.tcl
source recorder.tcl
source timebase.tcl
source trigger.tcl
source waveform.tcl
source digio.tcl
source firmware.tcl
source netalyzer.tcl
source interpolation.tcl


#Bring public commands into the global namespace
namespace import ::usbSerial::*

#---=== Core Procedures ===---

# showAbout
#
# Displays the about dialog box with software version and firmware revision from the device.
proc showAbout {} {
	tk_messageBox	\
		-message "Syscomp Electronic Design Ltd.\nCircuitGear GUI Version $::softwareVersion\n$usbSerial::firmwareIdent\nwww.syscompdesign.com"	\
		-default ok	\
		-icon info	\
		-title "About"
}

# initializeCGR
#
# Initializes the hardware on startup.  This procedure sends all the necessary commands to the hardware
# to ensure that it comes up in a predictable state.
proc initializeCGR {} {

	fconfigure $::portHandle -translation {binary lf}
	
	#Turn off strip chart mode, in case it is enabled
	sendCommand "X"
	
	#Read vertical scale calibration from the device
	cal::readConfig
	
	#Read the stored offset calibration values from the device
	scope::restoreOffsetCal
	trigger::restoreOffsetCal
	
	#Update the vertical scale settings in the hardware to match the GUI
	vertical::updateVertical
	
	#Set AC/DC coupling for both channels
	vertical::updateCoupling .scope.verticalA A
	vertical::updateCoupling .scope.verticalB B
	
	#Initialize the timebase & sampling settings
	timebase::adjustTimebase update

	#Initialize the trigger mode (auto)
	trigger::selectTriggerMode

	#Set up the trigger level
	trigger::updateTriggerLevel
	#Update the trigger hysteresis levels
	sendCommand "H $trigger::triggerLow $trigger::triggerHigh"

	#Initialize waveform generator controls
	set wavePath [wave::getWavePath]
	wave::adjustAmplitude [$wavePath.amp.ampSlider get]
	wave::adjustOffset [$wavePath.off.offSlider get]
	$wavePath.freq.freqSlider set 171
	$wavePath.wave.sine invoke

	#Start acquiring waveforms
	scope::acquireWaveform

}

# showManual
#
# Displays the device manual (PDF).  This procedure uses the operating system to open
# the PDF manual.
proc showManual {} {

	#Get the directory we are running in
	set scriptPath [file dirname [info script]]
	
	#Determine which operating system we are using - Windows or Linux/Mac
	if {$::osType=="windows"} {
		#Open the manual from the documentation directory if this is a full install
		if {[file exists "$scriptPath/../Documentation/CGM101-manual.pdf"]} {
			puts "Launching manual from Documenation directory"
			eval exec [auto_execok start] \"\" [list "$scriptPath/../Documentation/CGM101-manual.pdf"]
		} else {
			#Open the manual from the source code directory
			puts "Launcing manual from Source directory"
			eval exec [auto_execok start] \"\" [list "CGM101-manual.pdf"]
		}
	} else {
		#Linux - use the "see" command to have the OS pick the best application to open the PDF
		eval exec see [list "CGM101-manual.pdf"]
	}
}

# showChangeLog
#
# Displays the change log in a separate window with appropriate window dressings (scroll bars, etc)
proc showChangeLog {} {

	#Make sure the change log isn't already open
	if {[winfo exists .changeLog]} {
		raise .changeLog
		focus .changeLog
		return
	}
	
	#Create a new window to hold the log
	toplevel .changeLog
	wm title .changeLog "CGM-101 Change Log"
	
	#Open the change log and read it
	set fileId [open "Changes.txt" r]
	set changeData [read $fileId]
	close $fileId
	
	#Build widgets to display the log
	text .changeLog.log	\
		-width 80	\
		-yscrollcommand ".changeLog.scrollVert set"	\
		-xscrollcommand ".changeLog.scrollHor set"	\
		-wrap none
		
	.changeLog.log insert end $changeData
	.changeLog.log configure -state disabled
	
	scrollbar .changeLog.scrollVert	\
		-command ".changeLog.log yview"	\
		-orient vertical
		
	scrollbar .changeLog.scrollHor	\
		-command ".changeLog.log xview"	\
		-orient horizontal
		
	grid .changeLog.log -row 0 -column 0 -sticky news
	grid .changeLog.scrollVert -row 0 -column 1 -sticky ns
	grid .changeLog.scrollHor -row 1 -column 0 -sticky we
	grid rowconfigure .changeLog .changeLog.log -weight 1
	grid rowconfigure .changeLog .changeLog.scrollVert -weight 1
	grid columnconfigure .changeLog .changeLog.log -weight 1
	grid columnconfigure .changeLog .changeLog.scrollHor -weight 1
	
}

proc saveSettings {} {

	set types {
		{{Config Files}	{.cfg}}
	}
	
	set settingsFile [tk_getSaveFile -filetypes $types]
	
	if {$settingsFile == ""} {return}
	
	if {[catch {open "$settingsFile.cfg" w} fileId]} {
		tk_messageBox	\
			-message "Unable to write to saved settings file."	\
			-type ok	\
			-icon error
		saveSettings
		return
	}
	
	#Save the vertical settings
	puts $fileId $vertical::verticalIndexA
	puts $fileId $vertical::verticalIndexB
	puts $fileId $vertical::scopeProbeA
	puts $fileId $vertical::scopeProbeB
	
	#Save the timebase settings
	puts $fileId $timebase::timebaseIndex
	
	#Save trigger settings
	puts $fileId $trigger::triggerMode
	puts $fileId $trigger::triggerSlope
	puts $fileId $trigger::triggerSource
	
	#Save waveform generator frequency
	puts $fileId $wave::waveFrequency
	
	#Save waveform generator amplitude
	puts $fileId $wave::amplitude
	
	#Save waveform generator offset
	puts $fileId $wave::offset
	
	#Save current waveform file name
	puts $fileId $wave::currentWaveform
	
	#Save waveform generator frequency slider mode
	puts $fileId $wave::sliderMode
	
	#Save the state of the digital outputs
	puts $fileId $digio::digout(0)
	puts $fileId $digio::digout(1)
	puts $fileId $digio::digout(2)
	puts $fileId $digio::digout(3)
	puts $fileId $digio::digout(4)
	puts $fileId $digio::digout(5)
	puts $fileId $digio::digout(6)
	puts $fileId $digio::digout(7)

	#Save the pwm settings
	puts $fileId $digio::pwmDuty
	puts $fileId $digio::frequencyPosition
	
	#Save cursor settings
	if {$trigger::triggerSource == "A"} {
		puts $fileId [expr {$cursor::trigPos-$cursor::chAGndPos}]
	} else {
		puts $fileId [expr {$cursor::trigPos-$cursor::chBGndPos}]
	}
	puts $fileId $cursor::chAGndPos
	puts $fileId $cursor::chBGndPos

	close $fileId
	


}

proc loadSettings {} {

	set types {
		{{Config Files}	{.cfg}}
	}
	
	set settingsFile [tk_getOpenFile -filetypes $types]
	if {$settingsFile == ""} {
		return
	}
	
	#Open the file for reading
	if {[catch {open $settingsFile r}  fileId]} {
		tk_messageBox	\
			-message "Unable to open settings file."	\
			-type ok	\
			-icon warning
		return
	}
	
	#Read out all settings from the file
	set settings {}
	while {[gets $fileId line] >= 0} {
		lappend settings $line
	}
	close $fileId
	
	#Restore vertical settings
	set vertical::verticalIndexA [lindex $settings 0]
	set vertical::verticalIndexB [lindex $settings 1]
	vertical::adjustVertical .scope.verticalA A update
	vertical::adjustVertical .scope.verticalB B update
	cursor::measureVoltageCursors
	set vertical::probeA [lindex $settings 2]
	set vertical::probeB [lindex $settings 3]
	
	#Restore timebase setting
	set timebase::newTimebaseIndex [lindex $settings 4]
	timebase::adjustTimebase update

	#Restore trigger settings
	set trigger::triggerMode [lindex $settings 5]
	set trigger::triggerSlope [lindex $settings 6]
	set trigger::triggerSource [lindex $settings 7]
	trigger::selectTriggerMode

	#Restore waveform generator frequency
	set wave::waveFrequency [lindex $settings 8]
	wave::sendFrequency $wave::waveFrequency
	set wave::frequencyDisplay "$wave::waveFrequency Hz"
	
	#Restore waveform generator amplitude
	set wave::amplitude [lindex $settings 9]
	#wave::adjustAmplitude $wave::amplitude
	[wave::getWavePath].amp.ampSlider set $wave::amplitude
	
	#Restore waveform generator offset
	set wave::offset [lindex $settings 10]
	#wave::adjustOffset $wave::offset
	[wave::getWavePath].off.offSlider set $wave::offset
	
	#Restore current waveform
	switch [lindex $settings 11] {
		"sine" {
			[wave::getWavePath].wave.sine invoke
		} "square" {
			[wave::getWavePath].wave.square invoke
		} "sawtooth" {
			[wave::getWavePath].wave.sawtooth invoke
		} "custom" {
			[wave::getWavePath].wave.custom invoke
		}
	}
	
	#Restore waveform generator frequency slider mode
	set wave::sliderMode [lindex $settings 12]
	
	#Restore digital outputs
	if {[lindex $settings 13]} {digio::toggleOutBit 0}
	if {[lindex $settings 14]} {digio::toggleOutBit 1}
	if {[lindex $settings 15]} {digio::toggleOutBit 2}
	if {[lindex $settings 16]} {digio::toggleOutBit 3}
	if {[lindex $settings 17]} {digio::toggleOutBit 4}
	if {[lindex $settings 18]} {digio::toggleOutBit 5}
	if {[lindex $settings 19]} {digio::toggleOutBit 6}
	if {[lindex $settings 20]} {digio::toggleOutBit 7}

	#Restore PWM settings
	set digio::pwmDuty [lindex $settings 21]
	digio::updatePWM
	[digio::getDigioPath].pwm.freq.slider set [lindex $settings 22]
	
	#Restore cursor settings
	#set cursor::trigPos [lindex $settings 23]
	#set cursor::yStart  [expr {($display::yAxisEnd-$display::yAxisStart)/2.0}]
	#cursor::moveTrigger [expr {($display::yAxisEnd-$display::yAxisStart)/2.0 + $cursor::trigPos}]
	#set cursor::chAGndPos [lindex $settings 24]
	#set cursor::yStart [expr {($display::yAxisEnd-$display::yAxisStart)/2.0}]
	#cursor::moveChAGnd $cursor::chAGndPos
	#set cursor::chBGndPos [lindex $settings 25]
	#set cursor::yStart  [expr {($display::yAxisEnd-$display::yAxisStart)/2.0}]
	#cursor::moveChBGnd $cursor::chBGndPos
	
	
	
}

#---=== GUI Construction ===---
wm title . "Oscilloscope"
wm resizable . 0 0

#Create the menu bar
frame .menubar -relief raised -borderwidth 1

#Create the drop down menus

#File Menu
menubutton .menubar.file	\
	-text "File"		\
	-menu .menubar.file.filemenu
menu .menubar.file.filemenu -tearoff 0
.menubar.file.filemenu add command	\
	-label "Save Settings"	\
	-command saveSettings
.menubar.file.filemenu add command 	\
	-label "Load Settings"	\
	-command loadSettings
.menubar.file.filemenu add separator
.menubar.file.filemenu add command	\
	-label "Exit"	\
	-command {destroy .}

#View Menu
menubutton .menubar.scopeView \
	-text "View"	\
	-menu .menubar.scopeView.viewMenu
menu .menubar.scopeView.viewMenu -tearoff 0
if {$osType == "windows"} {
	.menubar.scopeView.viewMenu add command	\
		-label "Debug Console"	\
		-command {console show}
	.menubar.scopeView.viewMenu add separator
}
#Color Options
.menubar.scopeView.viewMenu add command	\
	-label "Color Options"	\
	-command display::showColorOptions
.menubar.scopeView.viewMenu add separator
#XY Mode selector
.menubar.scopeView.viewMenu add check	\
	-label "XY Mode"	\
	-variable display::xyEnable	\
	-command display::toggleXYMode
#Cursors
cursor::addCursorMenu
#Interpolation
.menubar.scopeView.viewMenu add separator
.menubar.scopeView.viewMenu add check	\
	-label "Interpolation"	\
	-variable interpEnable
set ::interpEnable 1

#Tools Menu
menubutton .menubar.tools	\
	-text "Tools"	\
	-menu .menubar.tools.toolsMenu
menu .menubar.tools.toolsMenu -tearoff 0
#Add offset calibration command to "Tools" menu
.menubar.tools.toolsMenu add command	\
	-label "Calibrate Scope Offsets"	\
	-command scope::showOffsetCal
#.menubar.tools.toolsMenu add command	\
#	-label "Calibrate Scope Vertical Scale"	\
#	-command cal::calibration
.menubar.tools.toolsMenu add separator
.menubar.tools.toolsMenu add command	\
	-label "Calibrate Trigger Offsets"	\
	-command trigger::showOffsetCal
.menubar.tools.toolsMenu add separator
#WaveMaker command
.menubar.tools.toolsMenu add command	\
	-label "WaveMaker Waveform Editor"	\
	-command waveMaker::showWaveMaker
.menubar.tools.toolsMenu add separator	
	

#Hardware Menu
menubutton .menubar.hardware	\
	-text "Hardware"	\
	-menu .menubar.hardware.hardwareMenu
menu .menubar.hardware.hardwareMenu	-tearoff 0
.menubar.hardware.hardwareMenu add command	\
	-label "Connect..."	\
	-command ::usbSerial::openSerialPort
.menubar.hardware.hardwareMenu add separator
#Selector for CircuitGear Mode
.menubar.hardware.hardwareMenu add check	\
	-label "CircuitGear Mode"	\
	-variable opMode			\
	-onvalue "CircuitGear"		\
	-command net::toggleOpMode
#Selector for Network Analyzer Mode
.menubar.hardware.hardwareMenu add check	\
	-label "Network Analyser Mode"	\
	-variable opMode			\
	-onvalue "Netalyzer"		\
	-offvalue "CircuitGear"		\
	-command net::toggleOpMode


#Help Menu
menubutton .menubar.help	\
	-text "Help"		\
	-menu .menubar.help.helpMenu
menu .menubar.help.helpMenu -tearoff 0
.menubar.help.helpMenu add command	\
	-label "About"	\
	-command showAbout
.menubar.help.helpMenu add separator
.menubar.help.helpMenu add command	\
	-label "Manual (pdf)"	\
	-command showManual
.menubar.help.helpMenu add separator
.menubar.help.helpMenu add command	\
	-label "Change Log"	\
	-command showChangeLog
.menubar.help.helpMenu add separator
.menubar.help.helpMenu add command	\
	-label "Firmware Upgrade..."	\
	-command firmware::showFirmware
.menubar.help.helpMenu add separator


#Create an indicator for the status of the serial-usb connection
label .menubar.serialPortStatus	\
	-textvariable ::usbSerial::serialStatus	\
	-background red
label .menubar.spacer	\
	-text "    "

#Place the menus on the menubar
grid .menubar.file -row 0 -column 0 -sticky w
grid .menubar.scopeView -row 0 -column 1 -sticky w
grid .menubar.tools -row 0 -column 2 -sticky w
grid .menubar.hardware -row 0 -column 3 -sticky w
grid .menubar.help -row 0 -column 4 -sticky w
grid .menubar.spacer -row 0 -column 5 -sticky w
grid .menubar.serialPortStatus -row 0 -column 6 -sticky w

#Build the Oscilloscope
scope::buildScope

#Build the Waveform Generator
toplevel .wave
wm title .wave "Waveform Generator"
wm resizable .wave 0 0
wm protocol .wave WM_DELETE_WINDOW {
	wm iconify .wave
}
wave::setWavePath .wave
wave::buildWave

#Build the Digital I/O Controls
toplevel .digio
wm title .digio "Digital I/O"
wm resizable .digio 0 0
wm protocol .digio WM_DELETE_WINDOW {
	wm iconify .digio
}
digio::setDigioPath .digio
digio::buildDigio

#Connection Animation
label .connection	\
	-image $statusImage(0)

#Place the major Frames
grid .menubar -row 0 -column 0 -sticky w
grid .connection -row 0 -column 1 -sticky e
grid .scope -row 1 -column 0 -columnspan 2

#Center the window on the screen
update
set width [winfo width .]
set height [winfo height .]
set screenWidth [winfo screenwidth .]
set screenHeight [winfo screenheight .]
set x 50
set y 25
set newGeo "+$x"
append newGeo "+$y"
wm geometry . $newGeo
#Digital I/O
set x 50
set y [expr {25+$height+30}]
set newGeo "+$x"
append newGeo "+$y"
wm geometry .digio $newGeo
#Waveform window
set x [expr {50+$width+20}]
set y 25
set newGeo "+$x"
append newGeo "+$y"
wm geometry .wave $newGeo

display::readColorSettings

#Add-ons
source wavemaker.tcl
source FFT.tcl
source automeasure.tcl
source math.tcl
source export.tcl
source updateCheck.tcl
source persist.tcl
source calibration.tcl

#Open a connection to the device
usbSerial::getStoredPort
usbSerial::openSerialPort





#Debug only
#console show