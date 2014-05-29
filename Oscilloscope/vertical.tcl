
namespace eval vertical {

set verticalPath .

set canvasSize 75

set enableA 1
set enableB 1
set invertA 0
set invertB 0
set couplingA DC
set couplingB DC

set verticalValues {0.01 0.02 0.05 0.1 0.2 0.5 1 2 5}
set maxVerticalIndex [expr {[llength $verticalValues] - 1}]
set preampAValues {}
set preampBValues {}

set verticalIndexA 6
set verticalIndexB 6

variable stepSizeHighDefault 0.025
variable stepSizeLowDefault 0.002481
variable stepSizeAHigh $stepSizeHighDefault
variable stepSizeALow $stepSizeLowDefault
variable stepSizeBHigh $stepSizeHighDefault
variable stepSizeBLow $stepSizeLowDefault

set scopeProbeA 1.0
set scopeProbeB 1.0

set attenA 0
set attenB 0

set offsetA 0
set offsetB 0

#Images
set zoomInImage [image create photo -file "$::images/MagIn.gif"]
set zoomOutImage [image create photo -file "$::images/MagOut.gif"]

}

proc vertical::buildVertical {verticalPath channelName} {
	
	#Make the frame pretty
	$verticalPath configure -relief groove -borderwidth 2
		
	#Create a canvas to indicate the vertical sensitivity
	canvas $verticalPath.display	\
		-width $vertical::canvasSize	\
		-height $vertical::canvasSize	\
		-background white
	#Draw a box
	$verticalPath.display create rectangle	\
		4 4	\
		 [expr {$vertical::canvasSize-1}]  [expr {$vertical::canvasSize-1}]	\
		 -dash {10 10} \
		 -fill ""	\
		 -outline black	\
		 -width 2
	variable "sensitivity$channelName" "1V/div"
	vertical::updateIndicator $verticalPath $channelName

	#Button to increase the vertical sensitivity
	button $verticalPath.zoomIn	\
		-image $vertical::zoomInImage	\
		-command "vertical::adjustVertical $verticalPath $channelName in"
		
	#Button to decrease the vertical sensitivity
	button $verticalPath.zoomOut	\
		-image $vertical::zoomOutImage	\
		-command "vertical::adjustVertical $verticalPath $channelName out"
	
	#Menu for Channel A Options
	menubutton $verticalPath.options	\
		-text "Options"	\
		-menu $verticalPath.options.optionsMenu	\
		-relief raised
	menu $verticalPath.options.optionsMenu -tearoff 0
	#Coupling Options
	$verticalPath.options.optionsMenu add radiobutton	\
		-label "Coupling: DC"	\
		-variable vertical::coupling$channelName	\
		-value "DC"	\
		-command "vertical::updateCoupling $verticalPath $channelName"
	$verticalPath.options.optionsMenu add radiobutton	\
		-label "Coupling: AC"	\
		-variable vertical::coupling$channelName	\
		-value "AC"	\
		-command "vertical::updateCoupling $verticalPath $channelName" 
	$verticalPath.options.optionsMenu add separator
	#Disable Trace
	set disableCommand "vertical::updateIndicator $verticalPath $channelName;"
	append disableCommand "cursor::reDrawCh$channelName"
	append disableCommand "GndCursor"
	$verticalPath.options.optionsMenu add check	\
		-label "Hide"	\
		-variable vertical::enable$channelName	\
		-onvalue 0	\
		-offvalue 1	\
		-command $disableCommand
	$verticalPath.options.optionsMenu add separator
	#Invert Trace
	$verticalPath.options.optionsMenu add check	\
		-label "Invert"	\
		-variable vertical::invert$channelName	\
		-onvalue 1	\
		-offvalue 0	\
		-command "vertical::updateIndicator $verticalPath $channelName"
	#Select Probe
	menu $verticalPath.options.optionsMenu.probeMenu -tearoff 0
	$verticalPath.options.optionsMenu add cascade	\
		-label "Probe..."	\
		-menu $verticalPath.options.optionsMenu.probeMenu
	$verticalPath.options.optionsMenu.probeMenu add check	\
		-label "1X"	\
		-variable vertical::scopeProbe$channelName	\
		-onvalue 1.0	\
		-command "vertical::updateIndicator $verticalPath $channelName; cursor::measureVoltageCursors"
	$verticalPath.options.optionsMenu.probeMenu add check	\
		-label "10X"	\
		-variable vertical::scopeProbe$channelName	\
		-onvalue 10.0	\
		-command "vertical::updateIndicator $verticalPath $channelName; cursor::measureVoltageCursors"
	$verticalPath.options.optionsMenu.probeMenu add check	\
		-label "100X"	\
		-variable vertical::scopeProbe$channelName	\
		-onvalue 100.0	\
		-command "vertical::updateIndicator $verticalPath $channelName; cursor::measureVoltageCursors"

	#grid $verticalPath.title -row 0 -column 0 -columnspan 2 -sticky we
	grid $verticalPath.display -row 1 -column 0 -columnspan 2
	grid $verticalPath.zoomIn -row 2 -column 0
	grid $verticalPath.zoomOut -row 2 -column 1
	grid $verticalPath.options -row 3 -column 0 -columnspan 2 -sticky we

	
}

proc vertical::updateIndicator {verticalPath channelName} {
	variable verticalValues
	variable verticalIndexA
	variable verticalIndexB

	#Channel Specific Parameters
	switch $channelName {
		"A" {
			set channelColor $display::channelAColor
			if $vertical::enableA {
				set sensitivity [vertical::formatAmplitude [vertical::getBoxSize A]]
			} else {
				set sensitivity "Disabled"
			}
			if $vertical::invertA {
				set inverted 1
			} else {
				set inverted 0
			}
			if {$vertical::couplingA == "DC"} {
				set coupling DC
			} else {
				set coupling AC
			}
			set probe [format "%.0d" [expr {round($vertical::scopeProbeA)}]]
			append probe "X"
		} "B" {
			set channelColor $display::channelBColor
			if $vertical::enableB {
				set sensitivity [vertical::formatAmplitude [vertical::getBoxSize B]]
			} else {
				set sensitivity "Disabled"
			}
			if $vertical::invertB {
				set inverted 1
			} else {
				set inverted 0
			}
			if {$vertical::couplingB == "DC"} {
				set coupling DC
			} else {
				set coupling AC
			}
			set probe [format "%.0d" [expr {round($vertical::scopeProbeB)}]]
			append probe "X"
		}
	}
	
	$verticalPath.display delete sensitivity
	
	#Draw Arrows
	$verticalPath.display create line	\
		[expr {$vertical::canvasSize/2.0}] [expr {$vertical::canvasSize/2.0-10}]	\
		[expr {$vertical::canvasSize/2.0}] 4	\
		-width 2	\
		-arrow last	\
		-fill $channelColor	\
		-tag sensitivity
	$verticalPath.display create line	\
		[expr {$vertical::canvasSize/2.0}] [expr {$vertical::canvasSize/2.0+10}]	\
		[expr {$vertical::canvasSize/2.0}] [expr {$vertical::canvasSize-1}]	\
		-width 2	\
		-arrow last	\
		-fill $channelColor	\
		-tag sensitivity
	
	#Update the Sensitivity
	$verticalPath.display create text	\
		[expr {$vertical::canvasSize/2.0}] [expr {$vertical::canvasSize/2.0}]	\
		-anchor center	\
		-text $sensitivity	\
		-fill $channelColor	\
		-font {-weight bold -size -12}	\
		-tag sensitivity
		
	#Update the inverted symbol
	$verticalPath.display delete invertedSymbol
	if $inverted {
		$verticalPath.display create oval	\
			[expr {$vertical::canvasSize/2.0+10}] [expr {$vertical::canvasSize/2.0+10}]	\
			[expr {$vertical::canvasSize/2.0+30}] [expr {$vertical::canvasSize/2.0+30}]	\
			-fill yellow	\
			-outline black	\
			-width 2	\
			-tag invertedSymbol
		$verticalPath.display create text	\
			[expr {$vertical::canvasSize/2.0+20}] [expr {$vertical::canvasSize/2.0+20}]	\
			-anchor center	\
			-fill black	\
			-text "I"	\
			-font {-weight bold -size -12}	\
			-tag invertedSymbol
	}
	
	#Update the AC/DC symbol
	$verticalPath.display delete couplingSymbol
	$verticalPath.display create text	\
		[expr {$vertical::canvasSize/2.0+20}] [expr {$vertical::canvasSize/2.0-20}]	\
		-anchor center	\
		-fill black	\
		-text $coupling	\
		-font {-weight bold -size -12}	\
		-tag couplingSymbol
		
	#Update the probe indicator
	$verticalPath.display delete probeSymbol
	$verticalPath.display create text	\
		[expr {$vertical::canvasSize/2.0-20}] [expr {$vertical::canvasSize/2.0-20}]	\
		-anchor center	\
		-fill black	\
		-text $probe	\
		-font {-weight bold -size -10}	\
		-tag probeSymbol
	
}

proc vertical::formatAmplitude {amp} {

	if {$amp < 1} {
		set temp [format "%.0f" [expr {$amp*1.0/0.001}]]
		return "$temp mV"
	} else {
		set temp [format "%.1f" $amp]
		return "$amp V"
	}
}

proc vertical::adjustVertical {verticalPath channelName dir} {
	variable verticalIndexA
	variable verticalIndexB

	switch $dir {
		"in" {
			if {$channelName=="A"} {
				set verticalIndexA [expr {$verticalIndexA-1}]
				if {$verticalIndexA <0} {set verticalIndexA 0}
			} elseif {$channelName=="B"} {
				set verticalIndexB [expr {$verticalIndexB-1}]
				if {$verticalIndexB <0} {set verticalIndexB 0}
			}
		} "out" {
			if {$channelName=="A"} {
				incr verticalIndexA
				if {$verticalIndexA > [expr [llength $vertical::verticalValues]-1]} {
					set verticalIndexA [expr [llength $vertical::verticalValues]-1]
				}
			} elseif {$channelName=="B"} {
				incr verticalIndexB
				if {$verticalIndexB > [expr [llength $vertical::verticalValues]-1]} {
					set verticalIndexB [expr [llength $vertical::verticalValues]-1]
				}
			}
		}
	}

	vertical::updateIndicator $verticalPath $channelName
	vertical::updateVertical
	
	#Update the shift voltage
	if {$channelName=="A"} {
		#set temp [lindex $calibrate::channelAOffsets $verticalIndexA]
		set cursor::yStart $cursor::chAGndPos
		cursor::moveChAGnd $cursor::chAGndPos
		[display::getDisplayPath].display delete chAValue
	} else {
		#set temp [lindex $calibrate::channelBOffsets $verticalIndexB]
		set cursor::yStart $cursor::chBGndPos
		cursor::moveChBGnd $cursor::chBGndPos
		[display::getDisplayPath].display delete chBValue
	}
	
	cursor::measureVoltageCursors
}

proc vertical::getBoxSize {channelName} {

	if {($channelName=="a")||($channelName=="A")} {
		return [expr {$vertical::scopeProbeA*[lindex $vertical::verticalValues $vertical::verticalIndexA]}]
	} else {
		return [expr {$vertical::scopeProbeB*[lindex $vertical::verticalValues $vertical::verticalIndexB]}]
	}
}

proc vertical::getStepSize {channel} {
	variable attenA
	variable attenB

	switch $channel {
		"A" {
			if {$attenA} {
				return $vertical::stepSizeAHigh
			} else {
				return $vertical::stepSizeALow
			}
		} "B" {
			if {$attenB} {
				return $vertical::stepSizeBHigh
			} else {
				return $vertical::stepSizeBLow
			}
		}
	}
	
}

proc vertical::convertSampleVoltage {sample channel} {

	if {($channel=="a")||($channel=="A")} {
		#Convert the sample value to a voltage value using the current vertical scale
		set voltage [expr {(1023-$sample)*[getStepSize A]}]
		if {$vertical::invertA} {set voltage [expr {$voltage*-1}]}
	} else {
		set voltage [expr {(1023-$sample)*[getStepSize B]}]
		if {$vertical::invertB} {set voltage [expr {$voltage*-1}]}
	}

	return $voltage

}

proc vertical::voltageToSample {voltage channel} {
	
	if {($channel=="a")||($channel=="A")} {
		set coord [expr {1023-($voltage/[getStepSize A])}]
		if {$vertical::invertA} {set coord [expr {$coord*-1}]}
	} else {
		set coord [expr {1023-($voltage/[getStepSize B])}]
		if {$vertical::invertB} {set coord [expr {$coord*-1}]}
	}
	
	return $coord

}

proc vertical::updateShift {channel voltage} {
	variable attenA
	variable attenB

	#Convert the voltage to D/A value
	if {($channel == "A") || ($channel == "a")} {
		if {$attenA} {
			set shiftNum [expr {2047-round($voltage/($vertical::stepSizeAHigh/2.0))+$scope::offsetAHigh}]
		} else {
			set shiftNum [expr {2047-round($voltage/($vertical::stepSizeALow/2.0))+$scope::offsetALow}]
		}
		if {$shiftNum < 0} {set shiftNum 0}
		if {$shiftNum > 4095} {set shiftNum 4095}
		sendCommand "o A $shiftNum"
		
	} else {
		if {$attenB} {
			set shiftNum [expr {2047-round($voltage/($vertical::stepSizeBHigh/2.0))+$scope::offsetBHigh}]
		} else {
			set shiftNum [expr {2047-round($voltage/($vertical::stepSizeBLow/2.0))+$scope::offsetBLow}]
		}
		if {$shiftNum < 0} {set shiftNum 0}
		if {$shiftNum > 4095} {set shiftNum 4095}
		sendCommand "o B $shiftNum"
	}
	
	#puts "ShiftNum $shiftNum"

}

proc vertical::updateCoupling {verticalPath channel} {

	if {$channel == "A"} {
		if {$vertical::couplingA == "DC"} {
			sendCommand "D A"
		} else {
			sendCommand "A A"
		}
		updateIndicator $verticalPath A
	} else {
		if {$vertical::couplingB == "DC"} {
			sendCommand "D B"
		} else {
			sendCommand "A B"
		}
		updateIndicator $verticalPath B
	}

	

}

proc vertical::updateVertical {} {
	variable attenA
	variable attenB

	#Channel A Attenuator
	if {$vertical::verticalIndexA <= 4} {
		sendCommand "P a"
		set attenA 0
	} else {
		sendCommand "P A"
		set attenA 1
	}
	
	#Channel B Attenuator
	if {$vertical::verticalIndexB <= 4} {
		sendCommand "P b"
		set attenB 0
	} else {
		sendCommand "P B"
		set attenB 1
	}
	
}

proc vertical::selectCustomProbe {channelName} {

	set newProbe [Dialog_Prompt newP "Enter probe type (e.g. 5.0):"]
	
	if {$newProbe == ""} {return}
	
	if {[string is double -strict $newProbe]} {
		if {$newProbe > 0} {
			set vertical::scopeProbe$channelName $newProbe
		} else {
			tk_messageBox	\
				-title "Invalid Probe Type"	\
				-default ok	\
				-message "Probe setting must be a positive number."	\
				-type ok	\
				-icon warning
		}
	} else {
		tk_messageBox	\
			-title "Invalid Probe Type"	\
			-default ok	\
			-message "Probe setting must be a positive number."
			-type ok	\
			-icon warning
	}
	
	
}



			