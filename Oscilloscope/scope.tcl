#File: scope.tcl
#Syscomp CircuitGear Mini Oscilloscope
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

#Procedure Index - scope.tcl
#	scope::buildScope
#	scope::processData
#	scope::acquireWaveform
#	scope::saveOffset
#	scope::restoreOffsetCal
#	scope::showOffsetCal
#	scope::startStripChart
#	scope::resetStripChart
#	scope::stopStripChart
#	scope::stripChartSample
#	scope::getStripSample

namespace eval scope {

#Multi-Dimensional array to hold samples from the scope
set scopeData {}

#Offset calibration values
set aLowOffsets {0 0 0 0 0 0 0}
set aHighOffsets {0 0 0 0 0 0 0}
set bLowOffsets {0 0 0 0 0 0 0}
set bHighOffsets {0 0 0 0 0 0 0}
set offsetA 0
set offsetALow 0
set offsetAHigh 0
set offsetB 0
set offsetBLow 0
set offsetBHigh 0
set offsetARange {}
set offsetBRange {}
set autoOffsetStatus ""
set autoOffsetProgress 0
set saveOffsetProgress 0

#Strip chart array and pointers
set stripData {}
set stripSample 0
set stripStart ""
set writeToDiskThreshold 100
set nextWriteToDisk $writeToDiskThreshold
set stripChartEnabled 0
set stripDataFile "stripChart.dat"
set samplesOnDisk 0

#Scope offset calibration
set scopeOffsetCalibrationInProgress 0
set scopeOffsetData {}

#Trigger State
set triggerState 0

}

# scope::buildScope
#
# Creates the various widgets that make up the oscilloscope display and
# arranges them.
proc scope::buildScope {} {

	#Main frame to hold all oscilloscope widgets
	labelframe .scope	\
		-relief groove	\
		-borderwidth 2	\
		-text "Oscilloscope"	\
		-font {-weight bold -size -12}
	
	#Construct the vertical controls
	labelframe .scope.verticalA	\
		-relief groove	\
		-borderwidth 2	\
		-text "Channel A"	\
		-font {-weight bold -size -12}
	vertical::buildVertical .scope.verticalA A
	labelframe .scope.verticalB	\
		-relief groove	\
		-borderwidth 2	\
		-text "Channel B"	\
		-font {-weight bold -size -12}
	vertical::buildVertical .scope.verticalB B
	
	#Create the scope display
	frame .scope.display -relief raised -borderwidth 2
	display::setDisplayPath .scope.display
	display::buildDisplay
	display::buildGraph
	display::setMode normal
		
	#Construct the timebase controls
	labelframe .scope.timebase	\
		-relief groove	\
		-borderwidth 2	\
		-text "Timebase"	\
		-font {-weight bold -size -12}
	
	timebase::buildControls .scope.timebase
	
	#Construct the trigger controls
	labelframe .scope.trigger	\
		-relief groove	\
		-borderwidth 2	\
		-text "Trigger"	\
		-font {-weight bold -size -12}
	trigger::buildControls .scope.trigger
	
	#Place scope frames
	grid .scope.verticalA -row 1 -column 0
	grid .scope.verticalB -row 2 -column 0
	grid .scope.display -row 1 -column 1 -padx 5 -rowspan 2
	grid .scope.timebase -row 1 -column 2 -padx 5
	grid .scope.trigger -row 2 -column 2 -padx 5
}

# scope::processData
#
# Accepts 1D array of data from the USB-serial port.  Converts data
# to 16-bit numbers and stores it in separate arrays for channel A and channel B
proc scope::processData {data} {
	variable scopeData
	variable triggerState
	
	#Create arrays for each channel
	set dataA {}
	set dataB {}
	
	#Pull the trigger state out of the data
	set triggerState [lindex $data 0]
	set data [lrange $data 1 end]
	
	#Pointer/counter for traversing data array
	set j 0
	
	#Process 1024 samples for each channel
	for {set i 0} {$i < 1024} {incr i} {
		
		#Get sample A
		set datum [lindex $data $j]
		set sample [expr {256*$datum}]
		incr j
		set datum [lindex $data $j]
		set sample [expr {$sample+$datum}]
		#Save the sample value
		lappend dataA $sample
		incr j
		
		#Get sample B
		set datum [lindex $data $j]
		set sample [expr {256*$datum}]
		incr j
		set datum [lindex $data $j]
		set sample [expr {$sample+$datum}]
		#Save the sample value
		lappend dataB $sample
		incr j
		
	}
	
	#Clear the existing scope data array and store the new values
	set scopeData {}
	lappend scopeData $dataA
	lappend scopeData $dataB
	
	#Save values for export
	set export::exportData {}
	#Add waveform data for channel A
	lappend export::exportData $dataA
	#Add waveform data for channel B
	lappend export::exportData $dataB
	#Add channel A step size
	lappend export::exportData [vertical::getStepSize A]
	#Add channel B step size
	lappend export::exportData [vertical::getStepSize B]
	#Add sampling rate
	lappend export::exportData [timebase::getSamplingRate]
	

	if {$::opMode == "CircuitGear"} {
		#Draw the new data on the screen
		display::plotData
		
		#Update the trigger display
		if {$trigger::triggerMode == "External"} {
			[display::getDisplayPath].statusBar configure -text "External Trigger"
		} else {
			if {$triggerState == 2} {
				[display::getDisplayPath].statusBar configure -text "Triggered"
			} else {
				[display::getDisplayPath].statusBar configure -text "Not Triggered"
			}
		}
		
		#XY Mode Service
		display::plotXY
		
		#Spectrum Analysis
		fft::updateFFT
		
		#Automatic measurements
		automeasure::automeasure
		
		#Math toolbox
		math::updateMath
	}
	
	#Get the next capture from the scope
	if {$trigger::triggerMode!="Single-Shot"} {
		after 100 {scope::acquireWaveform}
	}
	
	#See if we are calibrating scope offsets
	if {$scope::scopeOffsetCalibrationInProgress} {
		set scope::scopeOffsetData $scopeData
	}
}

# scope::acquireWaveform
#
# Requests a new capture from the hardware.
proc scope::acquireWaveform {} {

	#Make sure the sampling settings are up-to-date
	timebase::updateTimebase
			
	#Request a new capture
	sendCommand c
}

# scope::saveOffsets
#
# Save the current offset calibration values in the software to the hardware.
proc scope::saveOffsets {} {
	variable offsetALow
	variable offsetAHigh
	variable offsetBLow
	variable offsetBHigh
	
	#Replace the button with a progress bar while we save the values
	set scope::saveOffsetProgress 0
	
	set pos [grid info .offset.saveCal]
	grid remove .offset.saveCal
	grid .offset.saveProgress -row 3 -column 0 -pady 5 -columnspan 2
	update
	
	set sampleIndex 0
	set address $::nvmAddressOffsets
	for {set i 0} {$i <7} {incr i} {
	
		puts "Sample Index $sampleIndex"
		
		#Convert channel A calibration offsets to 12-bit unsigned values
		set aLow [expr {2047-[lindex $scope::aLowOffsets $sampleIndex]}]
		set aHigh [expr {2047-[lindex $scope::aHighOffsets $sampleIndex]}]
		
		#Convert channel B calibration offsets to 12-bit unsigned values
		set bLow [expr {2047-[lindex $scope::bLowOffsets $sampleIndex]}]
		set bHigh [expr {2047-[lindex $scope::bHighOffsets $sampleIndex]}]
		
		#Write the low range offsets for channel A to the device
		set byte1 [expr {round(floor($aLow/pow(2,8)))}]
		set byte0 [expr {$aLow%round(pow(2,8))}]
		sendCommand "E $address $byte1"
		after 100
		incr scope::saveOffsetProgress
		update
		incr address
		sendCommand "E $address $byte0"
		after 100
		incr scope::saveOffsetProgress
		update
		
		#Write the high range offsets for channel A to the device
		set byte1 [expr {round(floor($aHigh/pow(2,8)))}]
		set byte0 [expr {$aHigh%round(pow(2,8))}]
		incr address
		sendCommand "E $address $byte1"
		after 100
		incr scope::saveOffsetProgress
		update
		incr address
		sendCommand "E $address $byte0"
		after 100
		incr scope::saveOffsetProgress
		update
		
		#Write the low range offsets for channel B to the device
		set byte1 [expr {round(floor($bLow/pow(2,8)))}]
		set byte0 [expr {$bLow%round(pow(2,8))}]
		incr address
		sendCommand "E $address $byte1"
		after 100
		incr scope::saveOffsetProgress
		update
		incr address
		sendCommand "E $address $byte0"
		after 100
		incr scope::saveOffsetProgress
		update
		
		#Write the high range offsets for channel B to the device
		set byte1 [expr {round(floor($bHigh/pow(2,8)))}]
		set byte0 [expr {$bHigh%round(pow(2,8))}]
		incr address
		sendCommand "E $address $byte1"
		update
		after 100
		incr scope::saveOffsetProgress
		incr address
		sendCommand "E $address $byte0"
		update
		after 100
		incr scope::saveOffsetProgress
		
		incr address
		
		incr sampleIndex
	
	}
	
	grid remove .offset.saveProgress
	grid .offset.saveCal -row 3 -column 0 -pady 5 -columnspan 2
	
	tk_messageBox	\
		-default ok	\
		-message "Offsets saved to device."	\
		-parent .offset	\
		-title "Offsets Saved"	\
		-type ok
	
}

# scope::restoreOffsetCal
#
# Read offset calibration values from the device.
proc scope::restoreOffsetCal {} {

	set sampleIndex 0
	set address $::nvmAddressOffsets
	
	for {set i 0} {$i < 7} {incr i} {
		#Read the low range offset high byte for channel A
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte1 $usbSerial::eepromData
		puts "Data $usbSerial::eepromData"
		
		#Check to see if the value is "blank" (unprogrammed eeprom)
		if {$byte1 == 255} {
			puts "No scope offsets stored in hardware"
			return
		}
		
		#Read the low range offset low byte for channel A
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte0 $usbSerial::eepromData
		set scope::aLowOffsets [lreplace $scope::aLowOffsets $sampleIndex $sampleIndex [expr {2047-(256*$byte1+$byte0)}]]
		puts "Data $usbSerial::eepromData"
		
		#Read the high range offset for channel A
		incr address 
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte1 $usbSerial::eepromData
		puts "Data $usbSerial::eepromData"
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte0 $usbSerial::eepromData
		set scope::aHighOffsets [lreplace $scope::aHighOffsets $sampleIndex $sampleIndex [expr {2047-(256*$byte1+$byte0)}]]
		puts "Data $usbSerial::eepromData"
		
		
		#Read the low range offset for channel B
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte1 $usbSerial::eepromData
		puts "Data $usbSerial::eepromData"
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte0 $usbSerial::eepromData
		set scope::bLowOffsets [lreplace $scope::bLowOffsets $sampleIndex $sampleIndex [expr {2047-(256*$byte1+$byte0)}]]
		puts "Data $usbSerial::eepromData"
		
		#Read the high range offset for channel B
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte1 $usbSerial::eepromData
		puts "Data $usbSerial::eepromData"
		incr address
		sendCommand "e $address"
		vwait usbSerial::eepromData
		set byte0 $usbSerial::eepromData
		set scope::bHighOffsets [lreplace $scope::bHighOffsets $sampleIndex $sampleIndex [expr {2047-(256*$byte1+$byte0)}]]
		puts "Data $usbSerial::eepromData"
		
		incr address
		
		incr sampleIndex
	}
	
	puts "Scope offsets restored.$address"

}

# scope::showOffsetCal
#
# Display a window with sliders which lets the user adjust the offset
# calibration values for the device.
proc scope::showOffsetCal {} {

	#Check to see if the window is already open
	if {![winfo exists .offset]} {
	
		#Create a new window
		toplevel .offset
		wm title .offset "Scope Offset Calibration"
		wm iconname .offset "Offset"
		wm resizable .offset 0 0
		
		#Combobox for selecting sampling rate
		label .offset.sampleLabel	\
			-text "Sampling Rate:"	
		ttk::combobox .offset.sampleRate	\
			-values $timebase::samplingRates	\
			-textvariable scope::offsetSampleRate
		set scope::offsetSampleRate 2.0E6
		bind .offset.sampleRate <<ComboboxSelected>> scope::selectOffsetSamplingRate

		
		#Frame to hold offset controls
		labelframe .offset.controlsA	\
			-text "Channel A"	\
			-relief groove	\
			-borderwidth 2
			
		#Combobox for selecting the range
		ttk::combobox .offset.controlsA.rangeSelector	\
			-values {"High Range (500mV - 5V)" "Low Range (20mV - 200mV)"}	\
			-textvariable scope::offsetARange
		set scope::offsetARange "High Range (500mV - 5V)"
		bind .offset.controlsA.rangeSelector <<ComboboxSelected>> "scope::selectOffsetRange A"
		
		#Channel A High Range Offset Controls
		scale .offset.controlsA.aOffset	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable scope::offsetA	\
			-command "scope::offsetAdjustment A"
			
		grid .offset.controlsA.rangeSelector -row 0 -column 0
		grid .offset.controlsA.aOffset -row 1 -column 0
		
		#Frame to hold offset controls
		labelframe .offset.controlsB	\
			-text "Channel B"	\
			-relief groove	\
			-borderwidth 2
			
		#Combobox for selecting the range
		ttk::combobox .offset.controlsB.rangeSelector	\
			-values {"High Range (500mV - 5V)" "Low Range (20mV - 200mV)"}	\
			-textvariable scope::offsetBRange
		set scope::offsetBRange "High Range (500mV - 5V)"
		bind .offset.controlsB.rangeSelector <<ComboboxSelected>> "scope::selectOffsetRange B"
		
		#Channel A High Range Offset Controls
		scale .offset.controlsB.bOffset	\
			-from -300	\
			-to 300	\
			-length 150	\
			-resolution 1	\
			-showvalue 1	\
			-variable scope::offsetB	\
			-command "scope::offsetAdjustment B"
			
		grid .offset.controlsB.rangeSelector -row 0 -column 0
		grid .offset.controlsB.bOffset -row 1 -column 0
		
		#Button for autocalibration
		button .offset.autoCal	\
			-text "Auto Calibrate..."	\
			-command scope::autoOffsetCalibration
		
		#Button to save values to the hardware
		button .offset.saveCal	\
			-text "Save Calibration Values to Device"	\
			-command scope::saveOffsets
			
		#Progress bar for saving values to the hardware
		set scope::saveOffsetProgress 0
		ttk::progressbar .offset.saveProgress	\
			-orient horizontal	\
			-length 200	\
			-mode determinate	\
			-maximum 48	\
			-variable scope::saveOffsetProgress
		
		grid .offset.sampleLabel -row 0 -column 0
		grid .offset.sampleRate -row 0 -column 1
		grid .offset.controlsA -row 1 -column 0
		grid .offset.controlsB -row 1 -column 1
		grid .offset.autoCal -row 2 -column 0 -columnspan 2
		grid .offset.saveCal -row 3 -column 0 -pady 5 -columnspan 2
		
		#Initalize
		scope::selectOffsetSamplingRate
		scope::selectOffsetRange A
		scope::selectOffsetRange B
		
	} else {
		#Get rid of the old offset cal window and create a new one
		destroy .offset
		scope::showOffsetCal
	}

}

# scope::startStripChart
#
# This process switches the hardware from sampling mode to strip chart/scan mode.
proc scope::startStripChart {} {
	variable stripDataFile
	variable nextWriteToDisk
	variable writeToDiskThreshold
	variable samplesOnDisk
	
	#Figure out if we are in scan mode or strip chart mode
	if {$timebase::stripChartMode == "scan"} {
		#Scan mode - send the correct prescaler setting to the hardware for this timebase
		timebase::updateStripSamplePeriod [timebase::getPrescaler]
		#Update the status bar text
		[display::getDisplayPath].statusBar configure -text "Scan Mode"
	} else {
		#Strip chart mode - update the hardware with the correct sampling interval
		switch $timebase::stripChartSamplePeriod {
			"20" {timebase::updateStripSamplePeriod "D"}
			"50" {timebase::updateStripSamplePeriod "E"}
			"100" {timebase::updateStripSamplePeriod "F"}
			"200" {timebase::updateStripSamplePeriod "G"}
			"500" {timebase::updateStripSamplePeriod "H"}
			"1000" {timebase::updateStripSamplePeriod "I"}
			"2000" {timebase::updateStripSamplePeriod "J"}
		}
		#Update the status bar text
		[display::getDisplayPath].statusBar configure -text "Strip Chart Mode"
	}
	
	#Reset all counters and data structures
	scope::resetStripChart
	
	#If we are already in strip chart mode and the strip chart was running, stop here 
	#because the user has restarted sampling with the start button
	if {$scope::stripChartEnabled} {
		return
	}

	#Check to see if we are going to write the strip chart data to the disk
	if {$recorder::streamEnable} {
		#Check to see if the data file already exists
		if {[file exists $scope::stripDataFile]} {
			set answer [tk_messageBox	\
				-default no	\
				-icon warning	\
				-message "Warning: Strip chart data file exists.\nOverwrite it?"	\
				-parent .	\
				-title "File Exists..."	\
				-type yesno]
			if {$answer!="yes"} {return}
		}
		#Open the file and close it to erase contents
		set stripDataHandle [open $stripDataFile w]
		close $stripDataHandle
		#Set up for the next write to the file
		set nextWriteToDisk [expr {$writeToDiskThreshold+1}]
		set samplesOnDisk 0
	}
	
	#If we are in strip chart mode, disable the stream controls so they cannot
	#be changed unless the recording is stopped and restarted
	if {$timebase::timebaseMode == "strip"} {
		.recorder.recording.streamEnable configure -state disabled
		.recorder.recording.selectFile configure -state disabled
	}
	
	#Start the strip chart sampler
	sendCommand "C"
	
	#Get a sample
	set scope::stripChartEnabled 1
	sendCommand "F"
}

# scope::resetStripChart
#
# This process clears all data structures used by the strip chart in preparation
# for a new capture.
proc scope::resetStripChart {} {
	variable stripData
	variable stripSample
	variable stripStart
	
	#Clear data strcutres
	set stripData {}
	set stripSample 0
	
	#Reset the plot position on the graph display
	set display::xStart 0
	set display::xEnd 10
	set display::xSpan 10
	
	#Get the current time
	set temp [clock milliseconds]
	set now [clock format $temp -format "%D %T"]
	set stripStart $now

	#Reset the data array in the data recorder window
	if {$timebase::stripChartMode=="strip"} {
		array unset recorder::dataTable
	}

	#Clear the plot display and reset the x-axis
	display::clearDisplay
	display::xAxisLabels

}

# scope::stopStripChart
#
# Stops the current strip chart sampling
proc scope::stopStripChart {} {

	#Stop the strip chart sampler
	set scope::stripChartEnabled 0
	sendCommand "X"

	#Re-enable the stream controls
	if {$timebase::timebaseMode == "strip"} {
		.recorder.recording.streamEnable configure -state normal
		.recorder.recording.selectFile configure -state normal
	}

}

# scope::stripChartSample
#
# Processes 1D strip chart data received from the USB-serial port.
proc scope::stripChartSample {data} {
	variable stripData
	variable stripSample
	variable nextWriteToDisk
	variable samplesOnDisk
	variable writeToDiskThreshold
	variable stripDataFile

	if {[llength $data]} {
		#Process the raw data from the hardware
		set dataA [expr {[lindex $data 0]*256+[lindex $data 1]}]
		set dataB [expr {[lindex $data 2]*256+[lindex $data 3]}]

		#If we're in scan mode, reset the plot data once it reaches the right-hand side of the screen
		if {$timebase::stripChartMode=="scan"} {
		
			#Calculate the current x-position of the sample on the screen
			set xT [expr {[timebase::getSamplingPeriod]*$stripSample}]
		
			#Reset the current x-position if we have reached the right side of the screen
			if {$xT > [expr {$timebase::timebaseSetting*10.0}]} {
				scope::resetStripChart
				set xT 0
			}
			
			#Save the current sample to the strip chart display data array
			lappend stripData [list $stripSample $xT [vertical::convertSampleVoltage $dataA A] [vertical::convertSampleVoltage $dataB B]]
			incr stripSample
		} else {
			#Strip chart mode - calculate the x-position of this sample
			set xT [expr {$timebase::stripChartSamplePeriod*1.0E-3*$stripSample}]
		
			#Save the current samples to the strip chart display data array
			lappend stripData [list $stripSample $xT [vertical::convertSampleVoltage $dataA A] [vertical::convertSampleVoltage $dataB B]]
			incr stripSample
			
			#Check to see if we need to update the table
			if {$recorder::autoScroll} {
				set recorder::tableEndIndex $stripSample
				if {$recorder::tableEndIndex<10} {
					set recorder::tableEndIndex 10
				}
				set recorder::tableStartIndex [expr {$stripSample-9}]
				if {$recorder::tableStartIndex<0} {
					set recorder::tableStartIndex 0
				}
				recorder::updateDataTable
			}
			#See if we need to write this data to disk
			if {$stripSample==$nextWriteToDisk} {
				if {$::debugLevel>2} {
					puts "Strip chart write to disk"
				}
				set fileHandle [open $stripDataFile a]
				foreach sample $stripData {
					puts $fileHandle $sample
				}
				set samplesOnDisk $stripSample
				set nextWriteToDisk [expr {$stripSample+$writeToDiskThreshold}]
				close $fileHandle
			}
		}
			
		#Plot the data on the screen
		if {$timebase::stripChartMode=="scan"} {
			display::plotScan
		} else {
			display::plotStrip
		}
	}
	
	#Get the next sample
	if {($timebase::timebaseMode=="strip")||($timebase::timebaseMode=="scan")} {
		#Check to see if we have already requested the next sample
		sendCommand "F"
	}
}

# scope::getStripSample
#
# Extracts a sample (sampleNum) from the strip chart data array
proc scope::getStripSample {sampleNum} {
	variable stripData
	variable stripDataFile

	return [lindex $stripData $sampleNum]

}

# scope::selectOffsetSamplingRate
#
# Selects the appropriate timebase setting to match the current
# sampling rate in the offset calibration window
proc scope::selectOffsetSamplingRate {} {

	switch $scope::offsetSampleRate {
		2.0E6 {
			set timebase::newTimebaseIndex 5
			set sampleIndex 0
		} 1.0E6 {
			set timebase::newTimebaseIndex 6
			set sampleIndex 1
		} 500.0E3 {
			set timebase::newTimebaseIndex 7
			set sampleIndex 2
		} 250.0E3 {
			set timebase::newTimebaseIndex 8
			set sampleIndex 3
		} 125.0E3 {
			set timebase::newTimebaseIndex 8
			set sampleIndex 4
		} 62.5E3 {
			set timebase::newTimebaseIndex 9
			set sampleIndex 5
		}
	}
	
	set scope::offsetALow [lindex $scope::aLowOffsets $sampleIndex]
	set scope::offsetAHigh [lindex $scope::aHighOffsets $sampleIndex]
	set scope::offsetBLow [lindex $scope::bLowOffsets $sampleIndex]
	set scope::offsetBHigh [lindex $scope::bHighOffsets $sampleIndex]
	
	timebase::adjustTimebase update
	
	scope::selectOffsetRange A
	scope::selectOffsetRange B

}

# scope::saveOffsetToArray
#
# Saves the slider offsets to the offset arrays.
proc scope::saveOffsetToArray {} {

	switch $scope::offsetSampleRate {
		2.0E6 {
			set sampleIndex 0
		} 1.0E6 {
			set sampleIndex 1
		} 500.0E3 {
			set sampleIndex 2
		} 250.0E3 {
			set sampleIndex 3
		} 125.0E3 {
			set sampleIndex 4
		} 62.5E3 {
			set sampleIndex 5
		}
	}

	set scope::aLowOffsets [lreplace $scope::aLowOffsets $sampleIndex $sampleIndex $scope::offsetALow]
	set scope::aHighOffsets [lreplace $scope::aHighOffsets $sampleIndex $sampleIndex $scope::offsetAHigh]
	set scope::bLowOffsets [lreplace $scope::bLowOffsets $sampleIndex $sampleIndex $scope::offsetBLow]
	set scope::bHighOffsets [lreplace $scope::bHighOffsets $sampleIndex $sampleIndex $scope::offsetBHigh]
	

}

# scope::autoOffsetCabliration
#
# Iterates through all available sampling rates and calibrates the offset for each input channel and gain setting.
proc scope::autoOffsetCalibration {} {

	set answer [tk_messageBox	\
		-default no	\
		-icon warning	\
		-message "WARNING: Auto-Calibrate will replace all scope offset values.\nThis process will take 1-2 minutes\nWould you like to continue?"	\
		-parent .offset	\
		-title "Auto-Calibrate Warning"	\
		-type yesno]
		
	if {$answer=="no"} {return}
	
	tk_messageBox	\
		-default ok	\
		-icon warning	\
		-message "Remove all input signals, disconnect all BNC inputs and click OK to proceed"	\
		-parent .offset	\
		-title "Remove Input Sources"		\
		-type ok

	#Create a window to display the automatic offset calibration progress bar
	toplevel .autoOffset
	wm title .autoOffset "Automatic Offset Calibration"
	wm iconname .autoOffset "Auto Offset"
	wm resizable .autoOffset 0 0
	
	#Create a label to display the auto-calibration status
	set scope::autoOffsetStatus "Initializing..."
	label .autoOffset.status	\
		-textvariable scope::autoOffsetStatus
	
	#Create a progress bar
	set scope::autoOffsetProgress 0
	ttk::progressbar .autoOffset.progress	\
		-orient horizontal	\
		-length 200	\
		-mode determinate	\
		-maximum 12	\
		-variable scope::autoOffsetProgress
		
	grid .autoOffset.status -row 0 -column 0
	grid .autoOffset.progress -row 1 -column 0
	
	raise .autoOffset
	focus .autoOffset
	grab .autoOffset
	
	#Use single-shot trigger during auto-calibration
	set trigger::triggerMode "Single-Shot"
	trigger::selectTriggerMode
	trigger::manualTrigger

	#Flag to indicate that we are calibrating the offsets
	set scope::scopeOffsetCalibrationInProgress 1


	#Iterate through each sampling rate
	foreach sampleRate $timebase::samplingRates {
		#Update the sampling rate
		set scope::offsetSampleRate $sampleRate
		scope::selectOffsetSamplingRate
	
		#Select High Range for both channels
		set scope::autoOffsetStatus "Sample Rate: $sampleRate, Range: 0.5 - 5.0V"
		set vertical::verticalIndexA 5
		set vertical::verticalIndexB 5
		vertical::updateIndicator .scope.verticalA A
		vertical::updateIndicator .scope.verticalB B
		vertical::updateVertical
		
		set scope::offsetARange "High Range (500mV - 5V)"
		set scope::offsetBRange "High Range (500mV - 5V)"
		scope::selectOffsetRange A
		scope::selectOffsetRange B
		
		#Zero the offsets
		scope::zeroOffset A
		scope::zeroOffset B
		
		#Update the progress bar
		incr scope::autoOffsetProgress
		update
		
		#Select Low Range for both channels
		set scope::autoOffsetStatus "Sample Rate: $sampleRate, Range: 10mV - 200mV"
		set scope::offsetARange "Low Range (20mV - 200mV)"
		set scope::offsetBRange "Low Range (20mV - 200mV)"
		scope::selectOffsetRange A
		scope::selectOffsetRange B
		
		#Zero the offsets
		scope::zeroOffset A
		scope::zeroOffset B
		
		#Update the progress bar
		incr scope::autoOffsetProgress
		update
		
	}
	
	set trigger::triggerMode "Auto"
	trigger::selectTriggerMode
	
	set scope::scopeOffsetCalibrationInProgress 0
	
	set answer [tk_messageBox	\
		-default yes	\
		-message "Offset calibration complete.  Would you like to save the values?"	\
		-parent .autoOffset	\
		-title "Calibration Complete"	\
		-type yesno]
	
	destroy .autoOffset	
	update
	
	if {$answer == "yes"} {
		scope::saveOffsets
	}
}

proc scope::calculateAverage {channel} {

	for {set i 0} {$i < 5} {incr i} {
		#Capture one waveform
		trigger::singleShotReset
		trigger::manualTrigger
		#Wait for the data to arrive from the scope
		vwait scope::scopeOffsetData
	}

	if {$channel == "A"} {
		set data [lindex $scope::scopeData 0]
	} else {
		set data [lindex $scope::scopeData 1]
	}
	
	set average 0
	for {set i 0} {$i < 1024} {incr i} {
		set average [expr {$average+[lindex $data $i]}]
	}
	set average [expr {round($average/1024.0)}]

	return $average

}

proc scope::offsetAdjustment {channel newValue} {
	
	set offset [expr {2047+$newValue}]

	if {($channel=="A") || ($channel=="a")} {
		sendCommand "o A $offset"
		if {$scope::offsetARange == "High Range (500mV - 5V)"} {
			set scope::offsetAHigh $newValue 
		} else {
			set scope::offsetALow $newValue
		}
	} else {
		sendCommand "o B $offset"
		if {$scope::offsetBRange == "High Range (500mV - 5V)"} {
			set scope::offsetBHigh $newValue 
		} else {
			set scope::offsetBLow $newValue
		}
	}

	scope::saveOffsetToArray

}

proc scope::selectOffsetRange {channel} {

	if {$channel == "A"} {
		if {$scope::offsetARange == "High Range (500mV - 5V)"} {
			set offset $scope::offsetAHigh
			set vertical::verticalIndexA 5
		} else {
			set offset $scope::offsetALow
			set vertical::verticalIndexA 1
		}
		.offset.controlsA.aOffset set $offset
		vertical::updateIndicator .scope.verticalA A
		vertical::updateVertical
	} else {
		if {$scope::offsetBRange == "High Range (500mV - 5V)"} {
			set offset $scope::offsetBHigh
			set vertical::verticalIndexB 5
		} else {
			set offset $scope::offsetBLow
			set vertical::verticalIndexB 1
		}
		.offset.controlsB.bOffset set $offset
		vertical::updateIndicator .scope.verticalB B
		vertical::updateVertical
	}
}

proc scope::zeroOffset {channel} {

	set minValue -300
	set maxValue 300
	
	#Hunt down the correct offset
	for {set i 0} {$i <10} {incr i} {
	
		puts "Iteration $i"
		puts "Max $maxValue Min $minValue"
		
		set testOffset [expr {($maxValue-$minValue)/2+$minValue}]
		puts "Testing offset $testOffset"
		if {$channel == "A"} {
			.offset.controlsA.aOffset set $testOffset
		} else {
			.offset.controlsB.bOffset set $testOffset
		}
	
		set measuredOffset [scope::calculateAverage $channel]
		puts "Measured $measuredOffset"
		
		if {$measuredOffset == 1023} {
			break
		}
		
		if {$measuredOffset > 1023} {
			set maxValue $testOffset
		} else {
			set minValue $testOffset
		}
		update
	}

}