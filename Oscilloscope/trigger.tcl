#File: trigger.tcl
#Syscomp CGM-101 Graphic User Interface
#Trigger Routines and Controls

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

namespace eval trigger {

set triggerPath .

set canvasSize 75

set triggerSource A
set triggerSlope rising
set triggerMode Auto
set triggerModes {"Auto" "Normal" "Single-Shot" "External"}
set previousTriggerMode "None"

set preTriggerCount 0
set postTriggerCount 0

set triggerVoltage 0.0
set triggerSteps 512
set triggerHigh 15
set triggerLow 15

set pulseWidth 50
set pulseUnit ms

set triggerOffsetALow 0
set triggerOffsetAHigh 0
set triggerOffsetBLow 0
set triggerOffsetBHigh 0

set saveOffsetProgress 0
}

proc trigger::buildControls {triggerPath} {
	
	set trigger::triggerPath $triggerPath
	
	#Make the frame pretty
	$triggerPath configure -relief groove -borderwidth 2
		
	#Create the heading text
	label $triggerPath.title	\
		-text "Trigger"	\
		-font {-weight bold -size -12}	\
		-relief raised	

	#Create a canvas to indicate the trigger settings
	canvas $triggerPath.display	\
		-width $trigger::canvasSize	\
		-height $trigger::canvasSize	\
		-background white
	#Draw a box
	$triggerPath.display create rectangle	\
		4 4	\
		 [expr {$trigger::canvasSize-1}]  [expr {$trigger::canvasSize-1}]	\
		 -dash {10 10} \
		 -fill ""	\
		 -outline black	\
		 -width 2
	
	trigger::updateIndicator
	
	#Manual trigger button
	button $triggerPath.manualTrigger	\
		-text "Manual Trigger"	\
		-command trigger::manualTrigger
	
	#Trigger Mode
	label $triggerPath.modeTitle	\
		-text "Trigger Mode:"
	ttk::combobox $triggerPath.mode	\
		-justify center	\
		-textvariable trigger::triggerMode	\
		-values $trigger::triggerModes	\
		-width 10
	bind $triggerPath.mode <<ComboboxSelected>> trigger::selectTriggerMode
	button $triggerPath.singleShotReset	\
		-text "Single-Shot Reset"	\
		-command {trigger::singleShotReset}	\
		-state disabled
		
	#Options Menu
	menubutton $triggerPath.options	\
		-text "Options"	\
		-menu $triggerPath.options.optionsMenu	\
		-relief raised
	menu $triggerPath.options.optionsMenu -tearoff 0
	#Trigger Source
	$triggerPath.options.optionsMenu add cascade	\
		-label "Trigger Source:"	\
		-menu $triggerPath.options.optionsMenu.sourceMenu
	menu $triggerPath.options.optionsMenu.sourceMenu -tearoff 0
	$triggerPath.options.optionsMenu.sourceMenu add radiobutton	\
		-label "Channel A"	\
		-variable trigger::triggerSource	\
		-value "A"	\
		-command trigger::updateTriggerControl
	$triggerPath.options.optionsMenu.sourceMenu add radiobutton	\
		-label "Channel B"	\
		-variable trigger::triggerSource	\
		-value "B"	\
		-command trigger::updateTriggerControl
	#Trigger Slope
	$triggerPath.options.optionsMenu add cascade	\
		-label "Trigger Slope:"	\
		-menu $triggerPath.options.optionsMenu.slopeMenu
	menu $triggerPath.options.optionsMenu.slopeMenu -tearoff 0
	$triggerPath.options.optionsMenu.slopeMenu add radiobutton	\
		-label "Rising (+)"	\
		-variable trigger::triggerSlope	\
		-value "rising"	\
		-command trigger::updateTriggerControl
	$triggerPath.options.optionsMenu.slopeMenu add radiobutton	\
		-label "Falling (-)"	\
		-variable trigger::triggerSlope	\
		-value "falling"	\
		-command trigger::updateTriggerControl


	grid $triggerPath.title -row 0 -column 0 -columnspan 2 -sticky we
	grid $triggerPath.display -row 1 -column 0 -columnspan 2
	grid $triggerPath.manualTrigger -row 2 -column 0 -columnspan 2
	grid $triggerPath.modeTitle -row 3 -column 0 -columnspan 2
	grid $triggerPath.mode -row 4 -column 0 -columnspan 2
	grid $triggerPath.singleShotReset -row 5 -column 0 -columnspan 2 -sticky we
	grid $triggerPath.options -row 6 -column 0 -columnspan 2 -sticky we

	
}

proc trigger::selectTriggerMode {} {
	variable triggerPath
	variable previousTriggerMode
	
	
	#Enable/Disable the single-shot button depeding on the trigger mode
	if {$trigger::triggerMode!="Single-Shot"} {
		$triggerPath.singleShotReset configure -state disabled
	} else {
		$triggerPath.singleShotReset configure -state normal
	}
	
	#Enable/disable auto triggering in the hardware
	if {$trigger::triggerMode=="Auto"} {
		#Enable auto triggering
		sendCommand "R"
	} else {
		#Disable auto triggering
		sendCommand "r"
	}
	
	#Update internal/external
	trigger::updateTriggerControl
	
	#Start capturing if we've switched out of single-shot mode
	#if {$previousTriggerMode=="Single-Shot"} {
		scope::acquireWaveform
	#}
	set previousTriggerMode $trigger::triggerMode
	
}

proc trigger::updateAutoTriggerPeriod {period} {

	puts "Period is $period"

	set autoTriggerCount [expr {round(ceil($period/32E-6))}]

	if {$autoTriggerCount > 62500} {
		set autoTriggerCount 62500
	}
	
	if {$autoTriggerCount < 1000} {
		set autoTriggerCount 1000
	}

	sendCommand "a $autoTriggerCount"

}

proc trigger::updateTriggerControl {} {

	if {$trigger::triggerSlope == "rising"} {
		sendCommand "+"
	} else {
		sendCommand "-"
	}
	
	if {$trigger::triggerSource == "A"} {
		sendCommand "S"
	} else {
		sendCommand "s"
	}
	
	if {$trigger::triggerSource == "A"} {
		set cursor::yStart $cursor::chAGndPos
		cursor::moveChAGnd $cursor::chAGndPos
		[display::getDisplayPath].display delete chAValue
	} else {
		set cursor::yStart $cursor::chBGndPos
		cursor::moveChBGnd $cursor::chBGndPos
		[display::getDisplayPath].display delete chBValue
	}
	
	trigger::updateIndicator
	
	#Internal/External Trigger
	if {$trigger::triggerMode== "External"} {
		sendCommand Q
	} else {
		sendCommand q
	}

	
}

proc trigger::manualTrigger {} {
	sendCommand "M"
}

proc trigger::updateIndicator {} {
	variable triggerSource
	variable triggerSlope
	variable triggerPath

	$triggerPath.display delete trigger
	
	#Draw the ground reference line
	$triggerPath.display create line	\
		4 [expr {$trigger::canvasSize/2.0}]\
		 [expr {$trigger::canvasSize-4}] [expr {$trigger::canvasSize/2.0}]	\
		 -fill green	\
		 -dash .	\
		 -tag trigger
		 
	if {$triggerSource=="A"} {
		set slopeColor $display::channelAColor
	} elseif {$triggerSource=="B"} {
		set slopeColor $display::channelBColor
	}
	
	#Draw the trigger source indicator
	if {$triggerSlope=="rising"} {
		$triggerPath.display create text	\
			[expr {$trigger::canvasSize*0.25}] [expr {$trigger::canvasSize*0.25}]	\
			-text $triggerSource	\
			-font {-weight bold -size -14}	\
			-fill $slopeColor	\
			-tag trigger
	} else {
		$triggerPath.display create text	\
			[expr {$trigger::canvasSize*0.75}] [expr {$trigger::canvasSize*0.25}]	\
			-text $triggerSource	\
			-font {-weight bold -size -14}	\
			-fill $slopeColor	\
			-tag trigger
	}
	
	#Draw the trigger slope indicator
	if {$triggerSlope == "rising"} {
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.1}] [expr {$trigger::canvasSize*0.8}]	\
			[expr {$trigger::canvasSize*0.25}] [expr {$trigger::canvasSize*0.8}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.25}] [expr {$trigger::canvasSize*0.8}] \
			[expr {$trigger::canvasSize*0.6}] [expr {$trigger::canvasSize*0.4}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2	\
			-arrow last
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.6}] [expr {$trigger::canvasSize*0.4}]	\
			[expr {$trigger::canvasSize*0.75}] [expr {$trigger::canvasSize*0.2}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.75}] [expr {$trigger::canvasSize*0.2}]	\
			[expr {$trigger::canvasSize*0.9}] [expr {$trigger::canvasSize*0.2}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
	} else {
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.1}] [expr {$trigger::canvasSize*0.2}]	\
			[expr {$trigger::canvasSize*0.25}] [expr {$trigger::canvasSize*0.2}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.25}] [expr {$trigger::canvasSize*0.2}] \
			[expr {$trigger::canvasSize*0.6}] [expr {$trigger::canvasSize*0.6}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2	\
			-arrow last
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.6}] [expr {$trigger::canvasSize*0.6}]	\
			[expr {$trigger::canvasSize*0.75}] [expr {$trigger::canvasSize*0.8}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
		$triggerPath.display create line	\
			[expr {$trigger::canvasSize*0.75}] [expr {$trigger::canvasSize*0.8}]	\
			[expr {$trigger::canvasSize*0.9}] [expr {$trigger::canvasSize*0.8}]	\
			-fill $slopeColor	\
			-tag trigger	\
			-width 2
	
	}
					
}

proc trigger::updateTriggerLevel {} {
	variable triggerSteps
	variable triggerVoltage

	if {$trigger::triggerSource == "A"} {
		if {$vertical::attenA} {
			set offsetVoltage [expr {2047-round($cursor::chAGndVoltage/($vertical::stepSizeAHigh/2.0))+$scope::offsetAHigh}]
			set triggerSteps [expr {-1*round($triggerVoltage/($vertical::stepSizeAHigh/2.0))}]
			set triggerOffset $trigger::triggerOffsetAHigh
		} else {
			set offsetVoltage [expr {2047-round($cursor::chAGndVoltage/($vertical::stepSizeALow/2.0))+$scope::offsetALow}]
			set triggerSteps [expr {-1*round($triggerVoltage/($vertical::stepSizeALow/2.0))}]
			set triggerOffset $trigger::triggerOffsetALow
		}
	} else {
		if {$vertical::attenB} {
			set offsetVoltage [expr {2047-round($cursor::chBGndVoltage/($vertical::stepSizeBHigh/2.0))+$scope::offsetBHigh}]
			set triggerSteps [expr {-1*round($triggerVoltage/($vertical::stepSizeBHigh/2.0))}]
			set triggerOffset $trigger::triggerOffsetBHigh
		} else {
			set offsetVoltage [expr {2047-round($cursor::chBGndVoltage/($vertical::stepSizeBLow/2.0))+$scope::offsetBLow}]
			set triggerSteps [expr {-1*round($triggerVoltage/($vertical::stepSizeBLow/2.0))}]
			set triggerOffset $trigger::triggerOffsetBLow
		}
		
	}

	set triggerSteps [expr {$offsetVoltage+$triggerSteps+$triggerOffset}]

	if {$triggerSteps > 4095} {
		set triggerSteps 4095
	}
	if {$triggerSteps < 0} {
		set triggerSteps 0
	}

	sendCommand "T $triggerSteps"
	
	return
}

proc trigger::singleShotReset {} {

	set displayPath [display::getDisplayPath]
	
	$displayPath.display delete waveDataA
	$displayPath.display delete waveDataB
	
	scope::acquireWaveform
}

proc trigger::setPulseWidth {dummy} {


	if {$trigger::pulseUnit=="ms"} {
		set pulseLength [expr {$trigger::pulseWidth*1E-3}]
	} else {
		set pulseLength [expr {$trigger::pulseWidth*1E-6}]
	}
	
	if {$trigger::pulseWidth > 150E-3} {
		set $trigger::pulseWidth 150E-3
	}
	
	set pulseCount [expr {round(pow(2,24)-1-$pulseLength/10E-9)}]
	
	puts "pulse length $pulseLength pulse count $pulseCount"

	#Update the trigger pulse counter
	set byte2 [expr {round(floor($pulseCount/pow(2,16)))}]
	set temp [expr {$pulseCount%round(pow(2,16))}]
	set byte1 [expr {round(floor($temp/pow(2,8)))}]
	set byte0 [expr {$temp%round(pow(2,8))}]
	sendCommand "p $byte2 $byte1 $byte0"

}

proc trigger::updateHysteresis {} {

	#Get scaling values based on the trigger source
	if {$trigger::triggerSource == "A"} {
		set stepSize [vertical::getStepSize A]
		set boxSize [vertical::getBoxSize A]
	} else {
		set stepSize [vertical::getStepSize B]
		set boxSize [vertical::getBoxSize B]
	}

	#Upper trigger threshold
	set difference [expr {$cursor::trigPos-$cursor::trigUpperPos}]
	set numDiv [expr {$difference/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	set voltage [expr {$numDiv*$boxSize}]
	set trigger::triggerHigh [expr {abs(round($voltage/($stepSize/2.0)))}]
	
	#Lower trigger threshold
	set difference [expr {$cursor::trigPos-$cursor::trigLowerPos}]
	set numDiv [expr {$difference/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	set voltage [expr {$numDiv*$boxSize}]
	set trigger::triggerLow [expr {abs(round($voltage/($stepSize/2.0)))}]

	sendCommand "H $trigger::triggerLow $trigger::triggerHigh"

}

proc trigger::showOffsetCal {} {

	#Check to see if the window is already open
	if {![winfo exists .offset]} {
		
		#Create a new dialog
		toplevel .trigOffset
		wm title .trigOffset "Trigger Offset Calibration"
		wm iconname .trigOffset "Trigger Offset"
		wm resizable .trigOffset 0 0
		
		#Frame to hold offset controls
		labelframe .trigOffset.controls	\
			-text "Trigger Offsets"	\
			-relief groove	\
			-borderwidth 2
			
		#Channel A High Range Offset Controls
		label .trigOffset.controls.titleAHigh	\
			-text "Channel A High"
		scale .trigOffset.controls.highA	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable trigger::triggerOffsetAHigh	\
			-command {trigger::triggerOffsetScaleHandler}
			
		#Channel A Low Range Offset Controls
		label .trigOffset.controls.titleALow	\
			-text "Channel A Low"
		scale .trigOffset.controls.lowA	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable trigger::triggerOffsetALow		\
			-command {trigger::triggerOffsetScaleHandler}
			
		#Channel A High Range Offset Controls
		label .trigOffset.controls.titleBHigh	\
			-text "Channel B High"
		scale .trigOffset.controls.highB	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable trigger::triggerOffsetBHigh	\
			-command {trigger::triggerOffsetScaleHandler}
			
		#Channel A Low Range Offset Controls
		label .trigOffset.controls.titleBLow	\
			-text "Channel B Low"
		scale .trigOffset.controls.lowB	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable trigger::triggerOffsetBLow		\
			-command {trigger::triggerOffsetScaleHandler}
			
		grid .trigOffset.controls.titleAHigh -row 0 -column 0
		grid .trigOffset.controls.highA -row 1 -column 0
		grid .trigOffset.controls.titleALow -row 0 -column 1
		grid .trigOffset.controls.lowA -row 1 -column 1
		grid .trigOffset.controls.titleBHigh -row 0 -column 2
		grid .trigOffset.controls.highB -row 1 -column 2
		grid .trigOffset.controls.titleBLow -row 0 -column 3
		grid .trigOffset.controls.lowB -row 1 -column 3
		
		#Button to save the values to the hardware
		button .trigOffset.saveCal	\
			-text "Save Calibration Values to Device"	\
			-command trigger::saveOffsets
			
		#Progress bar for saving values to the hardware
		set trigger::saveOffsetProgress 0
		ttk::progressbar .trigOffset.saveProgress	\
			-orient horizontal	\
			-length 200	\
			-mode determinate	\
			-maximum 8	\
			-variable trigger::saveOffsetProgress
		
		grid .trigOffset.controls -row 0 -column 0
		grid .trigOffset.saveCal -row 1 -column 0
		
	}

}

proc trigger::saveOffsets {} {
	variable triggerOffsetAHigh
	variable triggerOffsetALow
	variable triggerOffsetBHigh
	variable triggerOffsetBLow
	
	#Replace the button with a progress bar while we save the values
	set trigger::saveOffsetProgress 0
	
	grid remove .trigOffset.saveCal
	grid .trigOffset.saveProgress -row 1 -column 0
	update
	
	#Convert the offset calibration values to 12-bit unsigned numbers
	set aHigh [expr {2047-$triggerOffsetAHigh}]
	set aLow [expr {2047-$triggerOffsetALow}]
	set bHigh [expr {2047-$triggerOffsetBHigh}]
	set bLow [expr {2047-$triggerOffsetBLow}]
	
	#Starting address in eeprom for the scope trigger offsets
	set address 64
	
	#Save the high trigger offset for Channel A
	update
	set byte1 [expr {round(floor($aHigh/pow(2,8)))}]
	set byte0 [expr {$aHigh%round(pow(2,8))}]
	sendCommand "E $address $byte1"
	after 100
	incr trigger::saveOffsetProgress
	update
	incr address
	sendCommand "E $address $byte0"
	after 100
	incr scope::saveOffsetProgress
	
	#Save the low trigger offset for Channel A
	update
	set byte1 [expr {round(floor($aLow/pow(2,8)))}]
	set byte0 [expr {$aLow%round(pow(2,8))}]
	incr address
	sendCommand "E $address $byte1"
	after 100
	incr trigger::saveOffsetProgress
	update
	incr address
	sendCommand "E $address $byte0"
	after 100
	incr scope::saveOffsetProgress
	
	#Save the high trigger offset for Channel B
	update
	set byte1 [expr {round(floor($bHigh/pow(2,8)))}]
	set byte0 [expr {$bHigh%round(pow(2,8))}]
	incr address
	sendCommand "E $address $byte1"
	after 100
	incr trigger::saveOffsetProgress
	update
	incr address
	sendCommand "E $address $byte0"
	after 100
	incr scope::saveOffsetProgress
	
	#Save the low trigger offset for Channel B
	update
	set byte1 [expr {round(floor($bLow/pow(2,8)))}]
	set byte0 [expr {$bLow%round(pow(2,8))}]
	incr address
	sendCommand "E $address $byte1"
	after 100
	incr trigger::saveOffsetProgress
	update
	incr address
	sendCommand "E $address $byte0"
	after 100
	incr scope::saveOffsetProgress

	#Restore the save button
	grid remove .trigOffset.saveProgress
	grid .trigOffset.saveCal -row 1 -column 0
	
	tk_messageBox	\
		-default ok	\
		-message "Offsets saved to device"	\
		-parent .trigOffset	\
		-title "Offsets Saved"	\
		-type ok
}

proc trigger::restoreOffsetCal {} {

	#Base address for trigger offsets in non-volatile memory
	set address 64
	
	#Read the high trigger offset for channel A
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte1 $usbSerial::eepromData
	
	#Check to see if the value is blank (unprogrammed eeprom)
	if {$byte1 == 255} {
		puts "No trigger offsets store in hardware"
		return
	}
	
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte0 $usbSerial::eepromData
	set trigger::triggerOffsetAHigh [expr {2047-(256*$byte1+$byte0)}]
	
	#Read the low trigger offset for channel A
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte1 $usbSerial::eepromData
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte0 $usbSerial::eepromData
	set trigger::triggerOffsetALow [expr {2047-(256*$byte1+$byte0)}]
	
	#Read the high trigger offset for channel B
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte1 $usbSerial::eepromData
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte0 $usbSerial::eepromData
	set trigger::triggerOffsetBHigh [expr {2047-(256*$byte1+$byte0)}]
	
	#Read the low trigger offset for channel A
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte1 $usbSerial::eepromData
	incr address
	sendCommand "e $address"
	vwait usbSerial::eepromData
	set byte0 $usbSerial::eepromData
	set trigger::triggerOffsetBLow [expr {2047-(256*$byte1+$byte0)}]

	puts "Trigger offsets restored"

}

proc trigger::triggerOffsetScaleHandler {scaleValue} {
	
	
	trigger::updateTriggerLevel
}
