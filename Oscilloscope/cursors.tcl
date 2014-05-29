#File: cursors.tcl
#Syscomp CGM-101 Graphic User Interface
#Screen Cursors

#JG
package provide cursors 1.0
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

namespace eval cursor {

set xStart [expr {($display::xAxisEnd-$display::xAxisStart)/2.0+$display::xAxisStart}]
set yStart [expr {($display::yAxisEnd-$display::yAxisStart)/2.0+$display::yAxisStart}]

#Trigger cursor
set trigPos [expr {($display::yAxisEnd-$display::yAxisStart)/2.0+$display::yAxisStart}]
set triggerVoltage 0
set trigUpperPos 0
set trigLowerPos 0

#Set ground cursor positions to mid-screen
set chAGndPos [expr {($display::yAxisEnd-$display::yAxisStart)/2.0+$display::yAxisStart}]
set chAGndVoltage 0
set chBGndPos [expr {($display::yAxisEnd-$display::yAxisStart)/2.0+$display::yAxisStart}]
set chBGndVoltage 0

set t1Pos [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/10.0}]
set t2Pos [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/10.0*3}]
set timeCursorsEnable 0
set timeMeasurePos [expr {$display::yAxisStart+20}]

set chACursorEnable 0
set va1Pos [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart-[display::getDisplayHeight]/10*4}]
set va2Pos [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart-[display::getDisplayHeight]/10*2}]
set vaMeasurePos [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/10*1.5}]

set chBCursorEnable 0
set vb1Pos [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart+[display::getDisplayHeight]/10*2}]
set vb2Pos [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart+[display::getDisplayHeight]/10*4}]
set vbMeasurePos [expr {$display::xAxisStart+[display::getDisplayWidth]/10*2.5}]

set waveOffsetA [expr {$cursor::chAGndPos-(($display::yAxisEnd-$display::yAxisStart)/2.0)}]
set waveOffsetB [expr {$cursor::chBGndPos-(($display::yAxisEnd-$display::yAxisStart)/2.0)}]

set hysteresisCursorEnable 0

set timePos [expr {$display::xAxisStart+($display::xAxisEnd-$display::xAxisStart)/2.0}]
set timeColor violet
set timeRatio 0.5

set trigColor green

}


#Mark X Start
#-------------
#This procedure  is used by the display when the time cursor is
#moved.  This procedure marks the starting point where the user
#initially grabbed the cursor.
proc cursor::markXStart { cursorTag xPos } {
	
	set dy 0
	
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	
	switch $cursorTag {
		"t1Cursor" {
			set snap [expr {$xPos - $cursor::t1Pos}]
			set cursor::t1Pos $xPos
			#calculateCursors
		} "t2Cursor" {
			set snap [expr {$xPos - $cursor::t2Pos}]
			set cursor::t2Pos $xPos
			#calculateCursors
		} "vaMeasure" {
			set snap [expr {$xPos - $cursor::vaMeasurePos}]
			set cursor::vaMeasurePos $xPos
		} "vbMeasure" {
			set snap [expr {$xPos - $cursor::vbMeasurePos}]
			set cursor::vbMeasurePos $xPos
		} "timePosCursor" {
			set snap [expr {$xPos - $cursor::timePos}]
			set cursor::timePos $xPos
		}
		
	}
	
	$displayPath move $cursorTag $snap $dy
	
	set cursor::xStart $xPos
}

#Mark Y Start
#-------------
#The procedure is used by the display when cursors are moved.
#The procedure marks the starting point where the user initially
#grabs the cursor.
proc cursor::markYStart { cursorTag yPos } {
	
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	set dx 0
	switch $cursorTag {
		"va1Cursor" {
			set snap [expr {$yPos - $cursor::va1Pos}]
			set cursor::va1Pos $yPos
			$displayPath move $cursorTag $dx $snap
			measureVoltageCursors
		} "va2Cursor" {
			set snap [expr {$yPos - $cursor::va2Pos}]
			set cursor::va2Pos $yPos
			$displayPath move $cursorTag $dx $snap
			measureVoltageCursors
		} "vb1Cursor" {
			set snap [expr {$yPos - $cursor::vb1Pos}]
			set cursor::vb1Pos $yPos
			$displayPath move $cursorTag $dx $snap
			measureVoltageCursors
		} "vb2Cursor" {
			set snap [expr {$yPos - $cursor::vb2Pos}]
			set cursor::vb2Pos $yPos
			$displayPath move $cursorTag $dx $snap
			measureVoltageCursors
		} "chAGnd" {
			set snap [expr {$yPos - $cursor::chAGndPos}]
			set cursor::chAGndPos $yPos
			$displayPath move $cursorTag $dx $snap
			if { $trigger::triggerSource == "A" } {
				cursor::reDrawTriggerCursor
			}
		} "chBGnd" {
			set snap [expr {$yPos - $cursor::chBGndPos}]
			set cursor::chBGndPos $yPos
			$displayPath move  $cursorTag $dx $snap
			if { $trigger::triggerSource == "B"} {
				cursor::reDrawTriggerCursor
			}
		} "trigLevelCursor" {
			set snap [expr {$yPos - $cursor::trigPos}]
			set cursor::trigPos $yPos
			$displayPath move $cursorTag $dx $snap
			if {$cursor::hysteresisCursorEnable} {
				$displayPath move trigUpperCursor $dx $snap
				$displayPath move trigLowerCursor $dx $snap
			}
		} "trigUpperCursor" {
			set snap [expr {$yPos - $cursor::trigUpperPos}]
			set cursor::trigUpperPos $yPos
			$displayPath move $cursorTag $dx $snap
		} "trigLowerCursor" {
			set snap [expr {$yPos - $cursor::trigLowerPos}]
			set cursor::trigLowerPos $yPos
			$displayPath move $cursorTag $dx $snap
		} "timeMeasure" {
			set snap [expr {$yPos - $cursor::timeMeasurePos}]
			set cursor::timeMeasurePos $yPos
			$displayPath move $cursorTag $dx $snap
		}
	}
	
	set cursor::yStart $yPos
}

#Used to initially draw the trigger point time cursor
proc cursor::drawXCursor {} {

	set displayPath [display::getDisplayPath]
	
	$displayPath.display create line	\
		$cursor::timePos $display::yAxisStart	\
		$cursor::timePos $display::yAxisEnd		\
		-tag timePosCursor	\
		-fill $cursor::timeColor
	$displayPath.display create text	\
		$cursor::timePos [expr $display::yAxisStart - 5]	\
		-fill $cursor::timeColor	\
		-tag timePosCursor	\
		-text "X"
		
	$displayPath.display bind timePosCursor <Button-1> {cursor::markXStart timePosCursor %x}
	$displayPath.display bind timePosCursor <B1-Motion> {cursor::moveTime %x}

}

proc cursor::reDrawXCursor {} {
	
	set displayPath [display::getDisplayPath]
	
	$displayPath.display delete timePosCursor
	
	#Calculate the new cursor position from the current time ratio
	set cursor::timePos [expr {$display::xAxisStart+$cursor::timeRatio*($display::xAxisEnd-$display::xAxisStart)}]
	
	#Redraw the cursor
	$displayPath.display create line	\
		$cursor::timePos $display::yAxisStart	\
		$cursor::timePos $display::yAxisEnd		\
		-tag timePosCursor	\
		-fill $cursor::timeColor
	$displayPath.display create text	\
		$cursor::timePos [expr $display::yAxisStart - 5]	\
		-fill $cursor::timeColor	\
		-tag timePosCursor	\
		-text "X"


}

proc cursor::moveTime {xPos} {

	#Check to see if we have hit the screen limits
	if {$xPos < $display::xAxisStart} {set xPos $display::xAxisStart}
	if {$xPos > $display::xAxisEnd} {set xPos $display::xAxisEnd}

	#Move the cursor on the screen
	set dy 0
	set dx [expr {$xPos-$cursor::xStart}]
	set cursor::xStart $xPos
	set cursor::timePos $xPos
	set displayPath [display::getDisplayPath]
	$displayPath.display move timePosCursor $dx $dy
	
	set cursor::timeRatio [expr {($xPos-$display::xAxisStart)*1.0/($display::xAxisEnd-$display::xAxisStart)}]
	
	

}

#Used initially to draw the trigger cursor
proc cursor::drawTriggerCursor {} {
	
	set displayPath [display::getDisplayPath]

	$displayPath.display create line	\
		$display::xAxisStart $cursor::trigPos	\
		$display::xAxisEnd $cursor::trigPos	\
		-tag trigLevelCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart - 5}] $cursor::trigPos	\
		-fill $cursor::trigColor	\
		-tag trigLevelCursor	\
		-text "T"

	$displayPath.display bind trigLevelCursor <Button-1> { cursor::markYStart trigLevelCursor %y}
	$displayPath.display bind trigLevelCursor <B1-Motion> {cursor::moveTrigger %y}
	$displayPath.display bind trigLevelCursor <ButtonRelease-1> {[display::getDisplayPath].display delete trigLevelValue}

}

#Used for resizing the display
proc cursor::reDrawTriggerCursor {} {

	set displayPath [display::getDisplayPath]
	
	$displayPath.display delete trigLevelCursor
	$displayPath.display delete trigLevelArrow
	
	#Back calculate the new trigger position from the trigger voltage
	if { $trigger::triggerSource == "A" } {
		set reference $cursor::chAGndPos
		set boxSize [vertical::getBoxSize A]
	} else {
		set reference $cursor::chBGndPos
		set boxSize [vertical::getBoxSize B]
	}
	set cursor::trigPos [expr {$reference-$cursor::triggerVoltage/$boxSize*($display::yAxisEnd-$display::yAxisStart)/10.0}]

	if {$cursor::trigPos < $display::yAxisStart} {
		set cursor::trigPos $display::yAxisStart
		set trigOffScreen top
	} elseif {$cursor::trigPos > $display::yAxisEnd} {
		set cursor::trigPos $display::yAxisEnd
		set trigOffScreen bottom
	} else {
		set trigOffScreen 0
	}

	$displayPath.display create line	\
		$display::xAxisStart $cursor::trigPos	\
		$display::xAxisEnd $cursor::trigPos	\
		-tag trigLevelCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart - 5}] $cursor::trigPos	\
		-fill $cursor::trigColor	\
		-tag trigLevelCursor	\
		-text "T"
	if {$trigOffScreen=="top"} {
		$displayPath.display create line	\
			[expr {$display::xAxisStart - 12}] [expr {$cursor::trigPos+5}]	\
			[expr {$display::xAxisStart - 12}] [expr {$cursor::trigPos - 5}]	\
			-arrow last	\
			-arrowshape {4 4 2}	\
			-fill $cursor::trigColor	\
			-tag trigLevelArrow
	} elseif {$trigOffScreen=="bottom"} {
		$displayPath.display create line	\
			[expr {$display::xAxisStart - 12}] [expr {$cursor::trigPos+5}]	\
			[expr {$display::xAxisStart - 12}] [expr {$cursor::trigPos - 5}]	\
			-arrow first	\
			-arrowshape {4 4 2}	\
			-fill $cursor::trigColor	\
			-tag trigLevelArrow
	}

	if {$cursor::hysteresisCursorEnable} {
		cursor::reDrawHysteresisCursors
	}

}

#Move Trigger
#--------------
#This procedure is called when the user drags the trigger cursor
#on the screen.  It calculates the trigger voltage corresponding
#to the current screen position and sends the appropriate command
#to the hardware.
proc cursor::moveTrigger { yPos } {

	set displayPath [display::getDisplayPath]

	#Determine whether the trigger source is A or B
	if { $trigger::triggerSource == "A" } {
		set reference $cursor::chAGndPos
		set boxSize [vertical::getBoxSize A]
	} else {
		set reference $cursor::chBGndPos
		set boxSize [vertical::getBoxSize B]
	}
	
	set stepSize [vertical::getStepSize $trigger::triggerSource]
	
	#Check to see if we have gone off of the screen
	if { $yPos > $display::yAxisEnd } { set yPos $display::yAxisEnd }
	if { $yPos < $display::yAxisStart } { set yPos $display::yAxisStart }
	
	
	#Calculate the difference between the trigger cursor
	#and its reference in A/D units
	set difference [expr {$reference-$yPos}]
	set numDiv [expr {$difference/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]

	#Check to see if we have exceeded the maximum or
	#minimum trigger level
	if { $numDiv < -5.0 } {
		set numDiv -5.0
		set yPos [expr {$reference - ($numDiv*($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	} 
	if {$numDiv > 5.0} {
		set numDiv 5.0
		set yPos [expr {$reference - ($numDiv*($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	}

	#Move the cursor on the screen
	set dx 0
	set dy [expr {$yPos - $cursor::yStart}]
	
	set cursor::yStart $yPos
	set cursor::trigPos $yPos
	$displayPath.display move trigLevelCursor $dx $dy
	if {$cursor::hysteresisCursorEnable} {
		cursor::reDrawHysteresisCursors
		$displayPath.display move trigUpperCursor $dx $dy
		$displayPath.display move trigLowerCursor $dx $dy
	}
	
	#Delete the off-screen arrow
	$displayPath.display delete trigLevelArrow
	
	#Calculate the trigger voltage that corresponds to the
	#current trigger cursor position
	set triggerVoltage [expr {$numDiv*$boxSize}]
	
	#Update the trigger level in the hardware
	set trigger::triggerVoltage $triggerVoltage
	trigger::updateTriggerLevel
	
	#Format the trigger voltage for the display
	set triggerVoltage [format "%.3f" $triggerVoltage]
	#Save the trigger voltage
	set cursor::triggerVoltage $triggerVoltage
	#Format the trigger voltage for the display
	set triggerVoltage "$triggerVoltage V"
	$displayPath.display delete trigLevelValue
	$displayPath.display create text	\
		[expr {$display::xAxisStart+30}] [expr {$cursor::trigPos - 5}]	\
		-fill black	\
		-tag trigLevelValue	\
		-text $triggerVoltage	\
		-font {-weight bold -size -14}
		
}

#Used to draw the trigger hysteresis cursors
proc cursor::drawHysteresisCursors {} {
	variable trigUpperPos
	variable trigLowerPos

	set displayPath [display::getDisplayPath]
	
	if {$trigger::triggerSource == "A"} {
		set stepSize [vertical::getStepSize A]
		set reference $cursor::chAGndPos
		set boxSize [vertical::getBoxSize A]
	} else {
		set stepSize [vertical::getStepSize B]
		set reference $cursor::chBGndPos
		set boxSize [vertical::getBoxSize B]
	}
	
	set upperVoltageDelta [expr {$stepSize/2.0*$trigger::triggerHigh}]
	set lowerVoltageDelta [expr {-1*$stepSize/2.0*$trigger::triggerLow}]
	
	set upperVoltage [expr {$cursor::triggerVoltage+$upperVoltageDelta}]
	set lowerVoltage [expr {$cursor::triggerVoltage+$lowerVoltageDelta}]
	
	set trigUpperPos [expr {$reference-$upperVoltage/$boxSize*($display::yAxisEnd-$display::yAxisStart)/10.0}]
	set trigLowerPos [expr {$reference-$lowerVoltage/$boxSize*($display::yAxisEnd-$display::yAxisStart)/10.0}]
	
	$displayPath.display create line	\
		$display::xAxisStart $trigUpperPos	\
		$display::xAxisEnd $trigUpperPos	\
		-tag trigUpperCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart + 2}] $trigUpperPos	\
		-fill $cursor::trigColor	\
		-tag trigUpperCursor	\
		-anchor sw	\
		-text "TH"
		
	$displayPath.display bind trigUpperCursor <Button-1> { cursor::markYStart trigUpperCursor %y}
	$displayPath.display bind trigUpperCursor <B1-Motion> {cursor::moveHysteresis %y upper}
	$displayPath.display bind trigUpperCursor <ButtonRelease-1> {[display::getDisplayPath].display delete thresholdValue}

	$displayPath.display create line	\
		$display::xAxisStart $trigLowerPos	\
		$display::xAxisEnd $trigLowerPos	\
		-tag trigLowerCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart + 2}] $trigLowerPos	\
		-fill $cursor::trigColor	\
		-tag trigLowerCursor	\
		-anchor nw	\
		-text "TL"
	
	$displayPath.display bind trigLowerCursor <Button-1> { cursor::markYStart trigLowerCursor %y}
	$displayPath.display bind trigLowerCursor <B1-Motion> {cursor::moveHysteresis %y lower}
	$displayPath.display bind trigLowerCursor <ButtonRelease-1> {[display::getDisplayPath].display delete thresholdValue}

}

#Used to draw the trigger hysteresis cursors
proc cursor::reDrawHysteresisCursors {} {
	variable trigUpperPos
	variable trigLowerPos

	set displayPath [display::getDisplayPath]
	
	$displayPath.display delete trigUpperCursor
	$displayPath.display delete trigLowerCursor
	
	if {$trigger::triggerSource == "A"} {
		set stepSize [vertical::getStepSize A]
		set reference $cursor::chAGndPos
		set boxSize [vertical::getBoxSize A]
	} else {
		set stepSize [vertical::getStepSize B]
		set reference $cursor::chBGndPos
		set boxSize [vertical::getBoxSize B]
	}
	
	set upperVoltageDelta [expr {$stepSize/2.0*$trigger::triggerHigh}]
	set lowerVoltageDelta [expr {-1*$stepSize/2.0*$trigger::triggerLow}]
	
	set upperVoltage [expr {$cursor::triggerVoltage+$upperVoltageDelta}]
	set lowerVoltage [expr {$cursor::triggerVoltage+$lowerVoltageDelta}]
	
	set trigUpperPos [expr {$reference-$upperVoltage/$boxSize*($display::yAxisEnd-$display::yAxisStart)/10.0}]
	set trigLowerPos [expr {$reference-$lowerVoltage/$boxSize*($display::yAxisEnd-$display::yAxisStart)/10.0}]
	
	$displayPath.display create line	\
		$display::xAxisStart $trigUpperPos	\
		$display::xAxisEnd $trigUpperPos	\
		-tag trigUpperCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart + 2}] $trigUpperPos	\
		-fill $cursor::trigColor	\
		-tag trigUpperCursor	\
		-anchor sw	\
		-text "TH"

	$displayPath.display create line	\
		$display::xAxisStart $trigLowerPos	\
		$display::xAxisEnd $trigLowerPos	\
		-tag trigLowerCursor	\
		-fill $cursor::trigColor
	$displayPath.display create text	\
		[expr {$display::xAxisStart + 2}] $trigLowerPos	\
		-fill $cursor::trigColor	\
		-tag trigLowerCursor	\
		-anchor nw	\
		-text "TL"

}

proc cursor::moveHysteresis { yPos upperLower} {

	set displayPath [display::getDisplayPath]

	#Determine whether the trigger source is A or B
	if {$trigger::triggerSource == "A"} {
		set stepSize [vertical::getStepSize A]
		set boxSize [vertical::getBoxSize A]
	} else {
		set stepSize [vertical::getStepSize B]
		set boxSize [vertical::getBoxSize B]
	}
	
	#Check to see if we have gone off of the screen
	if { $yPos > $display::yAxisEnd } { set yPos $display::yAxisEnd }
	if { $yPos < $display::yAxisStart } { set yPos $display::yAxisStart }
	
	if {$upperLower=="upper"} {
		if {$yPos > $cursor::trigPos} {set yPos $cursor::trigPos}
	} else {
		if {$yPos < $cursor::trigPos} {set yPos $cursor::trigPos}
	}
	
	#Calculate the difference between the trigger cursor
	#and its reference in A/D units
	set difference [expr {$cursor::trigPos-$yPos}]
	set numDiv [expr {$difference/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]

	#Move the cursor on the screen
	set dx 0
	set dy [expr {$yPos - $cursor::yStart}]
	
	set cursor::yStart $yPos
	if {$upperLower=="upper"} {
		set cursor::trigUpperPos $yPos
		$displayPath.display move trigUpperCursor $dx $dy
	} else {
		set cursor::trigLowerPos $yPos
		$displayPath.display move trigLowerCursor $dx $dy
	}
	
	#Calculate the trigger voltage that corresponds to the
	#current trigger cursor position
	set voltage [expr $numDiv*$boxSize]
	#set steps [expr {round($voltage/$stepSize)}]
	
	#if {$upperLower=="upper"} {
	#	set trigger::triggerHigh $steps
	#} else {
	#	set trigger::triggerLow [expr {abs($steps)}]
	#}
	
	#Update the trigger level in the hardware
	trigger::updateHysteresis
	
	#Format the trigger voltage for the display
	set thresholdVoltage [format "%.3f" $voltage]
	#Format the trigger voltage for the display
	set thresholdVoltage "$thresholdVoltage V"
	
	$displayPath.display delete thresholdValue
	if {$upperLower=="upper"} {
		$displayPath.display create text	\
			[expr {$display::xAxisEnd-30}] [expr {$cursor::trigUpperPos - 5}]	\
			-fill black	\
			-tag thresholdValue	\
			-text $thresholdVoltage	\
			-font {-weight bold -size -14}
	} else {
		$displayPath.display create text	\
			[expr {$display::xAxisEnd-30}] [expr {$cursor::trigLowerPos + 5}]	\
			-fill black	\
			-tag thresholdValue	\
			-text $thresholdVoltage	\
			-font {-weight bold -size -14}
	}
		
}

#Move Channel A Ground Reference
#------------------------------------
#This procedure is called when the user grabs the channel reference
#cursor and drags it up or down on the screen.  This procedure moves
#the cursor, ensures that the user doesn't drag the cursor off the 
#screen, and updates the waveform offset for plotting purposes.
proc cursor::moveChAGnd { yPos } {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	
	#Make sure we haven't gone off the screen
	set boxSize [lindex $vertical::verticalValues $vertical::verticalIndexA]
	if {$boxSize <=4.0} {
		if { $yPos > $display::yAxisEnd } { set yPos $display::yAxisEnd }
		if { $yPos < $display::yAxisStart } { set yPos $display::yAxisStart }
	} else {
		#Maximum offset is 20V - determine the number of divisions on the current scale equal to the limit
		set maxNumDiv [expr {20.0/$boxSize}]
		set yMax [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0+$maxNumDiv*($display::yAxisEnd-$display::yAxisStart)/10.0}]
		set yMin [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0-$maxNumDiv*($display::yAxisEnd-$display::yAxisStart)/10.0}]
		if {$yPos > $yMax} {set yPos $yMax}
		if {$yPos < $yMin} {set yPos $yMin}
	}
	
	#Move the cursor
	set dx 0
	set dy [expr $yPos - $cursor::yStart]
	set cursor::yStart $yPos
	set cursor::chAGndPos $yPos
	$displayPath move chAGnd $dx $dy
	
	#Calculate the voltage of the new ground position
	set numDiv [expr {(($display::yAxisEnd-$display::yAxisStart)/2.0-($cursor::chAGndPos-$display::yAxisStart))/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	set cursor::chAGndVoltage [expr {$numDiv*[vertical::getBoxSize A]}]

	#Update the hardware
	vertical::updateShift A $cursor::chAGndVoltage
	
	#Move the trigger cursor if trigger source is A
	if { $trigger::triggerSource == "A" } {
 		cursor::reDrawTriggerCursor
 		trigger::updateTriggerLevel
 	}

	
	#Format the reference voltage for the display
	set voltage [format "%.3f" $cursor::chAGndVoltage]
	set voltage "$voltage V"
	$displayPath delete chAValue
	$displayPath create text	\
		[expr {$display::xAxisStart+30}] [expr {$cursor::chAGndPos - 5}]	\
		-fill black	\
		-tag chAValue	\
		-text $voltage	\
		-font {-weight bold -size -14}
	
	
}

proc cursor::drawChAGndCursor {} {

	cursor::reDrawChAGndCursor

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	$displayPath bind chAGnd <Button-1> { cursor::markYStart chAGnd %y}
	$displayPath bind chAGnd <B1-Motion> { cursor::moveChAGnd %y }
	$displayPath bind chAGnd <ButtonRelease-1> "$displayPath delete chAValue"

}

proc cursor::reDrawChAGndCursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	
	$displayPath delete chAGnd
	
	if {!$vertical::enableA} {return}

	set height [expr {$display::yAxisEnd-$display::yAxisStart}]
	set cursor::chAGndPos [expr {($height)/2.0+$display::yAxisStart-$cursor::chAGndVoltage/[vertical::getBoxSize A]*($height)/10.0}]

	#Place the ground cursor for Channel A
	$displayPath create line \
		$display::xAxisStart $cursor::chAGndPos 	\
		$display::xAxisEnd $cursor::chAGndPos 	\
		-tag chAGnd 	\
		-fill $display::channelAColor		\
		-dash .

	$displayPath create text 	\
		[expr $display::xAxisEnd+5] $cursor::chAGndPos 	\
		-fill $display::channelAColor 		\
		-tag chAGnd 	\
		-text "A"

}

#Move Channel B Ground Reference
#------------------------------------
#This procedure is called when the user grabs the channel reference
#cursor and drags it up or down on the screen.  This procedure moves
#the cursor, ensures that the user doesn't drag the cursor off the 
#screen, and updates the waveform offset for plotting purposes.
proc cursor::moveChBGnd { yPos } {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	
	#Make sure we haven't gone off the screen
	set boxSize [lindex $vertical::verticalValues $vertical::verticalIndexB]
	if {$boxSize <=4.0} {
		if { $yPos > $display::yAxisEnd } { set yPos $display::yAxisEnd }
		if { $yPos < $display::yAxisStart } { set yPos $display::yAxisStart }
	} else {
		#Maximum offset is 20V - determine the number of divisions on the current scale equal to the limit
		set maxNumDiv [expr {20.0/$boxSize}]
		set yMax [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0+$maxNumDiv*($display::yAxisEnd-$display::yAxisStart)/10.0}]
		set yMin [expr {$display::yAxisStart+($display::yAxisEnd-$display::yAxisStart)/2.0-$maxNumDiv*($display::yAxisEnd-$display::yAxisStart)/10.0}]
		if {$yPos > $yMax} {set yPos $yMax}
		if {$yPos < $yMin} {set yPos $yMin}
	}

	#Move the cursor
	set dx 0
	set dy [expr $yPos - $cursor::yStart]
	set cursor::yStart $yPos
	set cursor::chBGndPos $yPos
	$displayPath move chBGnd $dx $dy
	
	#Calculate the voltage of the new ground position
	set numDiv [expr {(($display::yAxisEnd-$display::yAxisStart)/2.0-($cursor::chBGndPos-$display::yAxisStart))/(($display::yAxisEnd-$display::yAxisStart)/10.0)}]
	set cursor::chBGndVoltage [expr {$numDiv*[vertical::getBoxSize B]}]

	#Update the hardware
	vertical::updateShift B $cursor::chBGndVoltage
	
	#Move the trigger cursor if trigger source is B
	if { $trigger::triggerSource == "B" } {
		cursor::reDrawTriggerCursor
		trigger::updateTriggerLevel
	}
	
	#Format the reference voltage for the display
	set voltage [format "%.3f" $cursor::chBGndVoltage]
	set voltage "$voltage V"
	$displayPath delete chBValue
	$displayPath create text	\
		[expr {$display::xAxisStart+30}] [expr {$cursor::chBGndPos - 5}]	\
		-fill black	\
		-tag chBValue	\
		-text $voltage	\
		-font {-weight bold -size -14}

}

proc cursor::drawChBGndCursor {} {

	cursor::reDrawChBGndCursor

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	$displayPath bind chBGnd <Button-1> { cursor::markYStart chBGnd %y}
	$displayPath bind chBGnd <B1-Motion> { cursor::moveChBGnd %y }
	$displayPath bind chBGnd <ButtonRelease-1> "$displayPath delete chBValue"

}

proc cursor::reDrawChBGndCursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	
	$displayPath delete chBGnd
	
	if {!$vertical::enableB} {return}

	set height [expr {$display::yAxisEnd-$display::yAxisStart}]
	set cursor::chBGndPos [expr {($height)/2.0+$display::yAxisStart-$cursor::chBGndVoltage/[vertical::getBoxSize B]*($height)/10.0}]
	
	#Place the ground cursor for Channel B
	$displayPath create line \
		$display::xAxisStart $cursor::chBGndPos 	\
		$display::xAxisEnd $cursor::chBGndPos 	\
		-tag chBGnd 	\
		-fill $display::channelBColor 		\
		-dash .

	$displayPath create text 	\
		[expr $display::xAxisEnd+12] $cursor::chBGndPos 	\
		-fill $display::channelBColor 		\
		-tag chBGnd 	\
		-text "B"
}

#Toggle Time Cursors
#------------------------
#This process is used to toggle the time cursors.  When the 
#cursor are enabled this procedure draws the cursor lines and
#handles on the screen, binds mouse clicks on the cursors to 
#handler procedures, and adds measurement labels to the GUI.
#When the cursors are disabled, this procedure deletes the cursors
#and their handles from the canvas and removes the measurement
#labels from the GUI.
proc cursor::toggleTimeCursors {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	if {!$cursor::timeCursorsEnable} {
		
		
		$displayPath create line	\
			$cursor::t1Pos $display::yAxisStart \
			$cursor::t1Pos $display::yAxisEnd \
			-tag t1Cursor \
			-fill brown
		$displayPath create text \
			$cursor::t1Pos [expr {$display::yAxisStart -5}] \
			-fill brown \
			-tag t1Cursor \
			-text "T1"
		$displayPath create line \
			$cursor::t2Pos $display::yAxisStart \
			$cursor::t2Pos $display::yAxisEnd \
			-tag t2Cursor \
			-fill brown
		$displayPath create text \
			$cursor::t2Pos [expr {$display::yAxisStart -5}] \
			-fill brown \
			-tag t2Cursor \
			-text "T2"
		$displayPath bind t1Cursor <Button-1> {cursor::markXStart t1Cursor %x}
		$displayPath bind t1Cursor <B1-Motion> {cursor::moveTimeCursor t1Cursor %x}
		$displayPath bind t2Cursor <Button-1> {cursor::markXStart t2Cursor %x}
		$displayPath bind t2Cursor <B1-Motion> {cursor::moveTimeCursor t2Cursor %x}
		$displayPath bind timeMeasure <Button-1> {cursor::markYStart timeMeasure %y}
		$displayPath bind timeMeasure <B1-Motion> {cursor::moveTimePos %y}
		set cursor::timeCursorsEnable 1
		measureTimeCursors
	} else {
		#Disable the cursors
		$displayPath delete t1Cursor
		$displayPath delete t2Cursor
		$displayPath delete timeMeasure
		set cursor::timeCursorsEnable 0
	}
}

proc cursor::reDrawTimeCursors {} {

	

	if {$cursor::timeCursorsEnable} {
		
		if {$display::displayMode=="normal"} {
			set displayPath "[display::getDisplayPath].display"
		} else {
			set displayPath "[display::getDisplayPath].graph"
		}

		$displayPath delete t1Cursor
		$displayPath delete t2Cursor
		$displayPath delete timeMeasure
		
		$displayPath create line	\
			$cursor::t1Pos $display::yAxisStart \
			$cursor::t1Pos $display::yAxisEnd \
			-tag t1Cursor \
			-fill brown
		$displayPath create text \
			$cursor::t1Pos [expr {$display::yAxisStart -5}] \
			-fill brown \
			-tag t1Cursor \
			-text "T1"
		$displayPath create line \
			$cursor::t2Pos $display::yAxisStart \
			$cursor::t2Pos $display::yAxisEnd \
			-tag t2Cursor \
			-fill brown
		$displayPath create text \
			$cursor::t2Pos [expr {$display::yAxisStart -5}] \
			-fill brown \
			-tag t2Cursor \
			-text "T2"
		$displayPath bind t1Cursor <Button-1> {cursor::markXStart t1Cursor %x}
		$displayPath bind t1Cursor <B1-Motion> {cursor::moveTimeCursor t1Cursor %x}
		$displayPath bind t2Cursor <Button-1> {cursor::markXStart t2Cursor %x}
		$displayPath bind t2Cursor <B1-Motion> {cursor::moveTimeCursor t2Cursor %x}
		$displayPath bind timeMeasure <Button-1> {cursor::markYStart timeMeasure %y}
		$displayPath bind timeMeasure <B1-Motion> {cursor::moveTimePos %y}
		set cursor::timeCursorsEnable 1
		measureTimeCursors
	} 
	
}

#Move Time Cursor
#----------------
#This procedure is called when the user drags either time cursor on the
#screen.  The procedure ensures that the user does not drag the 
#cursor off of the edge of the screen and updates the global variable
#which stores the current location of the cursor.
proc cursor::moveTimeCursor { cursorName xPos } {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	#Check to see if we have gone off of the screen
	if { $xPos > $display::xAxisEnd} {set xPos $display::xAxisEnd}
	if { $xPos < $display::xAxisStart} { set xPos $display::xAxisStart}

	#Move the cursor on the screen
	set dy 0
	set dx [expr {$xPos - $cursor::xStart}]
	set cursor::xStart $xPos
	
	if {$cursorName == "t1Cursor"} {
		set cursor::t1Pos $xPos
	}
	if {$cursorName == "t2Cursor"} {
		set cursor::t2Pos $xPos
	}
	
	$displayPath move $cursorName $dx $dy
	
	cursor::measureTimeCursors
}

proc cursor::measureTimeCursors {} {

	if {!$cursor::timeCursorsEnable} {return}

	if {$cursor::t2Pos > $cursor::t1Pos} {
		set rightCursor $cursor::t2Pos
		set leftCursor $cursor::t1Pos
	} else {
		set rightCursor $cursor::t1Pos
		set leftCursor $cursor::t2Pos
	}
	
	if {$display::displayMode == "normal"} {
		#Get the timebase setting from the scope
		set horizontalBoxTime [lindex [lindex $timebase::validTimebases $timebase::timebaseIndex] 0]
		set horizontalBoxWidth [expr {($display::xAxisEnd-$display::xAxisStart)/10.0}]
		set pixelTime [expr {$horizontalBoxTime/$horizontalBoxWidth}]
		
		#Calculate the time between the cursors
		set cursorTime [expr {($rightCursor-$leftCursor)*$pixelTime}]
		
		if {$cursorTime != 0} {
			set cursorFreq [cursor::formatFrequency [expr {1.0/$cursorTime}] 1]
		} else {
			set cursorFreq "?"
		}
		set cursorFreq "($cursorFreq)"
	} else {
		set x1 [expr {$display::xStart+1.0*$display::xSpan*($leftCursor-$display::xAxisStart)/($display::xAxisEnd-$display::xAxisStart)}]
		set x2 [expr {$display::xStart+1.0*$display::xSpan*($rightCursor-$display::xAxisStart)/($display::xAxisEnd-$display::xAxisStart)}]
		set cursorTime [expr {$x2-$x1}]
		set cursorFreq ""
	}
	
	
	set cursorTime [cursor::formatTime $cursorTime]
		
		
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	
	$displayPath delete timeMeasure
	
	#Determine if we are drawing the time callout between the cursors
	#or outside of them
	if {[expr {$rightCursor - $leftCursor}] > 60} {
		$displayPath create line	\
			$leftCursor $cursor::timeMeasurePos	\
			$rightCursor $cursor::timeMeasurePos	\
			-fill black		\
			-tag timeMeasure	\
			-arrow both
		$displayPath create text \
			[expr {($rightCursor-$leftCursor)/2+$leftCursor}] [expr {$cursor::timeMeasurePos - 7}]	\
			-text $cursorTime	\
			-font {-weight bold -size -12}	\
			-tag timeMeasure	\
			-fill black
		$displayPath create text \
			[expr {($rightCursor-$leftCursor)/2+$leftCursor}] [expr {$cursor::timeMeasurePos + 7}]	\
			-text $cursorFreq	\
			-font {-weight bold -size -12}	\
			-tag timeMeasure	\
			-fill black
	} else {
		$displayPath create line	\
			$leftCursor $cursor::timeMeasurePos	\
			[expr {$leftCursor-40}] $cursor::timeMeasurePos	\
			-fill black		\
			-tag timeMeasure	\
			-arrow first
		$displayPath create line	\
			$rightCursor $cursor::timeMeasurePos	\
			[expr {$rightCursor+40}] $cursor::timeMeasurePos	\
			-fill black		\
			-tag timeMeasure	\
			-arrow first
		#Determine where we will draw the time measure
		if {$rightCursor > [expr {($display::xAxisEnd-$display::xAxisStart)/2.0}]} {
			$displayPath create text \
				[expr {$leftCursor-35}] [expr {$cursor::timeMeasurePos - 10}]	\
				-text $cursorTime	\
				-font {-weight bold -size -12}	\
				-tag timeMeasure	\
				-fill black
			$displayPath create text \
				[expr {$leftCursor-35}] [expr {$cursor::timeMeasurePos + 10}]	\
				-text $cursorFreq	\
				-font {-weight bold -size -12}	\
				-tag timeMeasure	\
				-fill black
		} else {
			$displayPath create text \
				[expr {$rightCursor+35}] [expr {$cursor::timeMeasurePos - 10}]	\
				-text $cursorTime	\
				-font {-weight bold -size -12}	\
				-tag timeMeasure	\
				-fill black
			$displayPath create text \
				[expr {$rightCursor+35}] [expr {$cursor::timeMeasurePos +10}]	\
				-text $cursorFreq	\
				-font {-weight bold -size -12}	\
				-tag timeMeasure	\
				-fill black

		}
	
	
	}

}

#Format Period
#---------------
#This procedure takes a number representing a time period and
#formats it into a string with the proper units.
proc cursor::formatTime {period} {

	if {$period < 1E-6} {
		set period [format "%3.2f" [expr $period/1E-9]]
		set period "$period ns"
	} elseif {$period < 1E-3} {
		set period [format "%3.2f" [expr $period/1E-6]]
		set period "$period us"
	} elseif {$period < 1.0} {
		set period [format "%3.2f" [expr $period/1E-3]]
		set period "$period ms"
	} else {
		set period [format "%3.2f" $period]
		set period "$period s"
	}
	return $period
}

proc cursor::moveTimePos { yPos } {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}


	#Make sure we haven't gone off the screen
	if { $yPos > $display::yAxisEnd } { set yPos $display::yAxisEnd }
	if { $yPos < $display::yAxisStart } { set yPos $display::yAxisStart }
	
	#Move the cursor
	set dx 0
	set dy [expr {$yPos - $cursor::yStart}]
	puts "dy $dy"
	set cursor::yStart $yPos
	set cursor::timeMeasurePos $yPos
	$displayPath move timeMeasure $dx $dy
	
}

proc cursor::toggleChACursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	if {!$cursor::chACursorEnable} {
		#Cursors for Channel A
		$displayPath create line	\
			$display::xAxisStart $cursor::va1Pos \
			$display::xAxisEnd $cursor::va1Pos \
			-tag va1Cursor \
			-fill red \
			-dash -
		$displayPath create text \
			[expr {$display::xAxisStart + 15}] [expr {$cursor::va1Pos - 10}]\
			-fill red \
			-tag va1Cursor \
			-text "VA1"
		$displayPath create line \
			$display::xAxisStart $cursor::va2Pos\
			$display::xAxisEnd $cursor::va2Pos\
			-tag va2Cursor \
			-fill red \
			-dash -
		$displayPath create text \
			[expr {$display::xAxisStart +15}] [expr {$cursor::va2Pos -10}] \
			-fill red \
			-tag va2Cursor \
			-text "VA2"
		
		#Bind Mouse clicks to the cursors
		$displayPath bind va1Cursor <Button-1> {cursor::markYStart va1Cursor %y}
		$displayPath bind va1Cursor <B1-Motion> {cursor::moveVcursor va1Cursor %y}
		
		$displayPath bind va2Cursor <Button-1> {cursor::markYStart va2Cursor %y}
		$displayPath bind va2Cursor <B1-Motion> {cursor::moveVcursor va2Cursor %y}
		
		$displayPath bind vaMeasure <Button-1> {cursor::markXStart vaMeasure %x}
		$displayPath bind vaMeasure <B1-Motion> {cursor::moveChAMeasurePos %x}
		$displayPath bind vaMeasure <ButtonRelease-1> {cursor::measureVoltageCursors}
		
		set cursor::chACursorEnable 1
		measureVoltageCursors
	
	} else {
		#Remove the cursors
		$displayPath delete va1Cursor
		$displayPath delete va2Cursor
		$displayPath delete vaMeasure
		
		set cursor::chACursorEnable 0
	}
}

proc cursor::reDrawChACursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	if {$cursor::chACursorEnable} {
		#Remove the cursors
		$displayPath delete va1Cursor
		$displayPath delete va2Cursor
		$displayPath delete vaMeasure
		
		#Check to see if we have gone off of the screen
		if { $cursor::va1Pos > $display::yAxisEnd} {set cursor::va1Pos $display::yAxisEnd}
		if { $cursor::va1Pos < $display::yAxisStart} { set cursor::va1Pos $display::yAxisStart}
		if { $cursor::va2Pos > $display::yAxisEnd} {set cursor::va2Pos $display::yAxisEnd}
		if { $cursor::va2Pos < $display::yAxisStart} { set cursor::va2Pos $display::yAxisStart}
	
	
		#Cursors for Channel A
		$displayPath create line	\
			$display::xAxisStart $cursor::va1Pos \
			$display::xAxisEnd $cursor::va1Pos \
			-tag va1Cursor \
			-fill red \
			-dash -
		$displayPath create text \
			[expr {$display::xAxisStart + 15}] [expr {$cursor::va1Pos - 10}]\
			-fill red \
			-tag va1Cursor \
			-text "VA1"
		$displayPath create line \
			$display::xAxisStart $cursor::va2Pos\
			$display::xAxisEnd $cursor::va2Pos\
			-tag va2Cursor \
			-fill red \
			-dash -
		$displayPath create text \
			[expr {$display::xAxisStart +15}] [expr {$cursor::va2Pos -10}] \
			-fill red \
			-tag va2Cursor \
			-text "VA2"
		
		#Bind Mouse clicks to the cursors
		$displayPath bind va1Cursor <Button-1> {cursor::markYStart va1Cursor %y}
		$displayPath bind va1Cursor <B1-Motion> {cursor::moveVcursor va1Cursor %y}
		
		$displayPath bind va2Cursor <Button-1> {cursor::markYStart va2Cursor %y}
		$displayPath bind va2Cursor <B1-Motion> {cursor::moveVcursor va2Cursor %y}
		
		$displayPath bind vaMeasure <Button-1> {cursor::markXStart vaMeasure %x}
		$displayPath bind vaMeasure <B1-Motion> {cursor::moveChAMeasurePos %x}
		$displayPath bind vaMeasure <ButtonRelease-1> {cursor::measureVoltageCursors}

		measureVoltageCursors
	
	} 

}

proc cursor::toggleChBCursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	if {!$cursor::chBCursorEnable} {
		#Cursors for Channel B
		$displayPath create line	\
			$display::xAxisStart $cursor::vb1Pos \
			$display::xAxisEnd $cursor::vb1Pos \
			-tag vb1Cursor \
			-fill blue \
			-dash -
		$displayPath create text \
			[expr $display::xAxisStart + 15] [expr $cursor::vb1Pos - 10]\
			-fill blue \
			-tag vb1Cursor \
			-text "VB1"
		$displayPath create line \
			$display::xAxisStart $cursor::vb2Pos\
			$display::xAxisEnd $cursor::vb2Pos\
			-tag vb2Cursor \
			-fill blue \
			-dash -
		$displayPath create text \
			[expr $display::xAxisStart +15] [expr $cursor::vb2Pos -10] \
			-fill blue \
			-tag vb2Cursor \
			-text "VB2"
		
		#Bind Mouse clicks to the cursors
		$displayPath bind vb1Cursor <Button-1> {cursor::markYStart vb1Cursor %y}
		$displayPath bind vb1Cursor <B1-Motion> {cursor::moveVcursor vb1Cursor %y}
		
		$displayPath bind vb2Cursor <Button-1> {cursor::markYStart vb2Cursor %y}
		$displayPath bind vb2Cursor <B1-Motion> {cursor::moveVcursor vb2Cursor %y}
		
		$displayPath bind vbMeasure <Button-1> {cursor::markXStart vbMeasure %x}
		$displayPath bind vbMeasure <B1-Motion> {cursor::moveChBMeasurePos %x}
		$displayPath bind vbMeasure <ButtonRelease-1> {cursor::measureVoltageCursors}
		
		set cursor::chBCursorEnable 1
		measureVoltageCursors
	
	} else {
		#Remove the cursors
		$displayPath delete vb1Cursor
		$displayPath delete vb2Cursor
		$displayPath delete vbMeasure
		
		set cursor::chBCursorEnable 0
	}
}

proc cursor::reDrawChBCursor {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	if {$cursor::chBCursorEnable} {
		#Remove the cursors
		$displayPath delete vb1Cursor
		$displayPath delete vb2Cursor
		$displayPath delete vbMeasure
		
		#Check to see if we have gone off of the screen
		if { $cursor::vb1Pos > $display::yAxisEnd} {set cursor::vb1Pos $display::yAxisEnd}
		if { $cursor::vb1Pos < $display::yAxisStart} { set cursor::vb1Pos $display::yAxisStart}
		if { $cursor::vb2Pos > $display::yAxisEnd} {set cursor::vb2Pos $display::yAxisEnd}
		if { $cursor::vb2Pos < $display::yAxisStart} { set cursor::vb2Pos $display::yAxisStart}
	
		#Cursors for Channel B
		$displayPath create line	\
			$display::xAxisStart $cursor::vb1Pos \
			$display::xAxisEnd $cursor::vb1Pos \
			-tag vb1Cursor \
			-fill blue \
			-dash -
		$displayPath create text \
			[expr $display::xAxisStart + 15] [expr $cursor::vb1Pos - 10]\
			-fill blue \
			-tag vb1Cursor \
			-text "VB1"
		$displayPath create line \
			$display::xAxisStart $cursor::vb2Pos\
			$display::xAxisEnd $cursor::vb2Pos\
			-tag vb2Cursor \
			-fill blue \
			-dash -
		$displayPath create text \
			[expr $display::xAxisStart +15] [expr $cursor::vb2Pos -10] \
			-fill blue \
			-tag vb2Cursor \
			-text "VB2"
		
		#Bind Mouse clicks to the cursors
		$displayPath bind vb1Cursor <Button-1> {cursor::markYStart vb1Cursor %y}
		$displayPath bind vb1Cursor <B1-Motion> {cursor::moveVcursor vb1Cursor %y}
		
		$displayPath bind vb2Cursor <Button-1> {cursor::markYStart vb2Cursor %y}
		$displayPath bind vb2Cursor <B1-Motion> {cursor::moveVcursor vb2Cursor %y}
		
		$displayPath bind vbMeasure <Button-1> {cursor::markXStart vbMeasure %x}
		$displayPath bind vbMeasure <B1-Motion> {cursor::moveChBMeasurePos %x}
		$displayPath bind vbMeasure <ButtonRelease-1> {cursor::measureVoltageCursors}
		
		measureVoltageCursors
	
	}


}

proc cursor::moveVcursor { vTag vPos } {
	
	#Check to see if we have gone off of the screen
	if { $vPos > $display::yAxisEnd} {set vPos $display::yAxisEnd}
	if { $vPos < $display::yAxisStart} { set vPos $display::yAxisStart}

	#Move the cursor on the screen
	set dx 0
	set dy [expr $vPos - $cursor::yStart]
	set cursor::yStart $vPos
	
	#Save the new position
	switch $vTag {
		"va1Cursor" {
			set cursor::va1Pos $vPos
		} "va2Cursor" {
			set cursor::va2Pos $vPos
		} "vb1Cursor" {
			set cursor::vb1Pos $vPos
		} "vb2Cursor" {
			set cursor::vb2Pos $vPos
		}
	}
	
	#Move the cursor line on the screen
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}

	$displayPath move $vTag $dx $dy
	
	#Update cursor label displays
	measureVoltageCursors
}

proc cursor::measureVoltageCursors {} {

	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}


	if {$cursor::chACursorEnable} {
	
		if {$cursor::va1Pos > $cursor::va2Pos} {
			set topCursor $cursor::va2Pos
			set bottomCursor $cursor::va1Pos
		} else {
			set topCursor $cursor::va1Pos
			set bottomCursor $cursor::va2Pos
		}
		
		#Get the vertical sensitivity settings for channel A from the scope
		set pixelSize [expr {[vertical::getBoxSize A]*10/[display::getDisplayHeight]}]
		
		#Calculate the voltage between the cursors
		set cursorVoltage [expr {($bottomCursor-$topCursor)*$pixelSize}]
		set cursorVoltage [cursor::formatAmplitude $cursorVoltage]
		
		$displayPath delete vaMeasure
		
		#Determine which side of the arrows we will draw the voltage measurement
		if {$cursor::vaMeasurePos < [expr {[display::getDisplayWidth]/2.0+$display::xAxisStart}]} {
			set textPos [expr {$cursor::vaMeasurePos+30}]
		} else {
			set textPos [expr {$cursor::vaMeasurePos-30}]
		}
		
		#Determine if we are drawing the voltage measure between the cursors
		#or outside of them
		if {[expr {$bottomCursor - $topCursor}] > 40} {
			$displayPath create line	\
				$cursor::vaMeasurePos $bottomCursor	\
				$cursor::vaMeasurePos $topCursor	\
				-fill black		\
				-tag vaMeasure	\
				-arrow both
			$displayPath create text \
				$textPos [expr {$bottomCursor-($bottomCursor-$topCursor)/2}]	\
				-text $cursorVoltage	\
				-font {-weight bold -size -12}	\
				-tag vaMeasure	\
				-fill black
		} else {
			$displayPath create line	\
				$cursor::vaMeasurePos $topCursor	\
				$cursor::vaMeasurePos [expr {$topCursor-40}]	\
				-fill black		\
				-tag vaMeasure	\
				-arrow first
			$displayPath create line	\
				$cursor::vaMeasurePos $bottomCursor	\
				$cursor::vaMeasurePos [expr {$bottomCursor+40}]	\
				-fill black		\
				-tag vaMeasure	\
				-arrow first
			#Determine where we will draw the time measure
			if {$topCursor > [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart}]} {
				$displayPath create text \
					$textPos [expr {$topCursor-35}] \
					-text $cursorVoltage	\
					-font {-weight bold -size -12}	\
					-tag vaMeasure	\
					-fill black
			} else {
				$displayPath create text \
					$textPos [expr {$bottomCursor + 35}]	\
					-text $cursorVoltage	\
					-font {-weight bold -size -12}	\
					-tag vaMeasure	\
					-fill black
			}
		
		
		}
		
	}
	
	if {$cursor::chBCursorEnable} {
	
		if {$cursor::vb1Pos > $cursor::vb2Pos} {
			set topCursor $cursor::vb2Pos
			set bottomCursor $cursor::vb1Pos
		} else {
			set topCursor $cursor::vb1Pos
			set bottomCursor $cursor::vb2Pos
		}
		
		#Get the vertical sensitivity settings for channel A from the scope
		set pixelSize [expr {[vertical::getBoxSize B]*10/[display::getDisplayHeight]}]
		
		#Calculate the voltage between the cursors
		set cursorVoltage [expr {($bottomCursor-$topCursor)*$pixelSize}]
		set cursorVoltage [cursor::formatAmplitude $cursorVoltage]
		
		$displayPath delete vbMeasure
		
		#Determine which side of the arrows we will draw the voltage measurement
		if {$cursor::vbMeasurePos < [expr {[display::getDisplayWidth]/2.0+$display::xAxisStart}]} {
			set textPos [expr {$cursor::vbMeasurePos+30}]
		} else {
			set textPos [expr {$cursor::vbMeasurePos-30}]
		}
		
		#Determine if we are drawing the voltage measure between the cursors
		#or outside of them
		if {[expr {$bottomCursor - $topCursor}] > 40} {
			$displayPath create line	\
				$cursor::vbMeasurePos $bottomCursor	\
				$cursor::vbMeasurePos $topCursor	\
				-fill black		\
				-tag vbMeasure	\
				-arrow both
			$displayPath create text \
				$textPos [expr {$bottomCursor-($bottomCursor-$topCursor)/2}]	\
				-text $cursorVoltage	\
				-font {-weight bold -size -12}	\
				-tag vbMeasure	\
				-fill black
		} else {
			$displayPath create line	\
				$cursor::vbMeasurePos $topCursor	\
				$cursor::vbMeasurePos [expr {$topCursor-40}]	\
				-fill black		\
				-tag vbMeasure	\
				-arrow first
			$displayPath create line	\
				$cursor::vbMeasurePos $bottomCursor	\
				$cursor::vbMeasurePos [expr {$bottomCursor+40}]	\
				-fill black		\
				-tag vbMeasure	\
				-arrow first
			#Determine where we will draw the time measure
			if {$topCursor > [expr {[display::getDisplayHeight]/2.0+$display::yAxisStart}]} {
				$displayPath create text \
					$textPos [expr {$topCursor-35}] \
					-text $cursorVoltage	\
					-font {-weight bold -size -12}	\
					-tag vbMeasure	\
					-fill black
			} else {
				$displayPath create text \
					$textPos [expr {$bottomCursor + 35}]	\
					-text $cursorVoltage	\
					-font {-weight bold -size -12}	\
					-tag vbMeasure	\
					-fill black
			}
		
		
		}
		
	}

}

#Format Amplitude
#-------------------
#This procedure takes a number representing a voltage and
#formats it into a string with the proper units.
proc cursor::formatAmplitude {voltage} {

	if {[expr {abs($voltage)}] < 1.0} {
		set voltage [format "%3.0f" [expr $voltage/1E-3]]
		set voltage "$voltage mV"
	} else {
		set voltage [format "%2.2f" $voltage]
		set voltage "$voltage V"
	}

	return $voltage
}

proc cursor::formatFrequency {freq decPoints} {
	
	set formatString "%3."
	append formatString $decPoints
	append formatString "f"
	
	if {$freq > 1E6} {
		set freq [format $formatString [expr $freq/1E6]]
		set freq "$freq MHz"
	} elseif { $freq > 1E3} {
		set freq [format $formatString [expr $freq/1E3]]
		set freq "$freq kHz"
	} else {
		set freq [format $formatString $freq]
		set freq "$freq Hz"
	}
	return $freq
	
}

proc cursor::moveChAMeasurePos { xPos } {

	#Make sure we haven't gone off the screen
	if { $xPos > $display::xAxisEnd } { set xPos $display::xAxisEnd }
	if { $xPos < $display::xAxisStart } { set xPos $display::xAxisStart }
	
	#Move the cursor
	set dy 0
	set dx [expr $xPos - $cursor::xStart]
	set cursor::xStart $xPos
	set cursor::vaMeasurePos $xPos
	
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	$displayPath move vaMeasure $dx $dy
	
}

proc cursor::moveChBMeasurePos { xPos } {

	#Make sure we haven't gone off the screen
	if { $xPos > $display::xAxisEnd } { set xPos $display::xAxisEnd }
	if { $xPos < $display::xAxisStart } { set xPos $display::xAxisStart }
	
	#Move the cursor
	set dy 0
	set dx [expr $xPos - $cursor::xStart]
	set cursor::xStart $xPos
	set cursor::vbMeasurePos $xPos
	
	if {$display::displayMode=="normal"} {
		set displayPath "[display::getDisplayPath].display"
	} else {
		set displayPath "[display::getDisplayPath].graph"
	}
	$displayPath move vbMeasure $dx $dy
	
}

proc cursor::screenXToSampleIndex {x} {

	#Get the timebase setting
	#set timebaseSetting [lindex $scope::timebaseValues $scope::timebaseIndex]
	
	#Calculate the sampling frequency
	#set sampleRate [lindex $scope::samplingRates $scope::timebaseIndex]
	#set sampleRate [expr {$scope::masterSampleRate/pow(2,$sampleRate)}]

	#return [expr {round(1024-5-$cursor::sampleOffset-($sampleRate*$timebaseSetting*10/$scope::xPlotWidth)*($cursor::timePos-$x))}]
	
	#Determine the spacing between samples
	set displayTime [expr {10.0*$timebase::timebaseSetting}]
	set pixelTime [expr {$displayTime/($display::xAxisEnd-$display::xAxisStart)}]
	
	return [expr {round($pixelTime*($x-$display::xAxisStart)/($timebase::sampleIncrement*[timebase::getSamplingPeriod]))}]

}

proc cursor::createCursorPopup {displayPath} {

	#Create a pop-up menu for the cursors
	menu $displayPath.popup -tearoff 0
	$displayPath.popup add command	\
		-label "Toggle Time Cursors"	\
		-command cursor::toggleTimeCursors
	$displayPath.popup add command	\
		-label "Toggle Channel A Cursors"	\
		-command cursor::toggleChACursor
	$displayPath.popup add command	\
		-label "Toggle Channel B Cursors"	\
		-command cursor::toggleChBCursor
	if {$::osType == "Darwin"} {
		bind $displayPath <Button-2> "+tk_popup $displayPath.popup %X %Y"
	} else {
		bind $displayPath <Button-3> "+tk_popup $displayPath.popup %X %Y"
	}
	
}

proc cursor::toggleHysteresisCursors {} {
	variable hysteresisCursorEnable
	
	if {$hysteresisCursorEnable} {
		cursor::drawHysteresisCursors
	} else {
		[display::getDisplayPath].display delete trigUpperCursor
		[display::getDisplayPath].display delete trigLowerCursor
	}
}

proc cursor::addCursorMenu {} {

	#Add the cursor commands to the view menu
	.menubar.scopeView.viewMenu add separator
	.menubar.scopeView.viewMenu add command	\
		-label "Toggle Time Cursors"	\
		-command cursor::toggleTimeCursors
	.menubar.scopeView.viewMenu add command	\
		-label "Toggle Channel A Cursors"	\
		-command cursor::toggleChACursor
	.menubar.scopeView.viewMenu add command	\
		-label "Toggle Channel B Cursors"	\
		-command cursor::toggleChBCursor
	.menubar.scopeView.viewMenu add separator
	.menubar.scopeView.viewMenu add check	\
		-label "Show Trigger Hysteresis Cursors"	\
		-variable cursor::hysteresisCursorEnable	\
		-command cursor::toggleHysteresisCursors
}




