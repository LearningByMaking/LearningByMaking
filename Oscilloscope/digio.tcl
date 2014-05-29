
package provide digio 1.0
package require Img
package require BWidget

namespace eval digio {

#---=== Digital I/O Global Variables ===---
variable digout
set digout(7) 0
set digout(6) 0
set digout(5) 0
set digout(4) 0
set digout(3) 0
set digout(2) 0
set digout(1) 0
set digout(0) 0

#Digital I/O Images:
set bitOffImages(7) [image create photo -file "$images/Bit7Off.png"]
set bitOnImages(7) [image create photo -file "$images/Bit7On.png"]
set bitOffImages(6) [image create photo -file "$images/Bit6Off.png"]
set bitOnImages(6) [image create photo -file "$images/Bit6On.png"]
set bitOffImages(5) [image create photo -file "$images/Bit5Off.png"]
set bitOnImages(5) [image create photo -file "$images/Bit5On.png"]
set bitOffImages(4) [image create photo -file "$images/Bit4Off.png"]
set bitOnImages(4) [image create photo -file "$images/Bit4On.png"]
set bitOffImages(3) [image create photo -file "$images/Bit3Off.png"]
set bitOnImages(3) [image create photo -file "$images/Bit3On.png"]
set bitOffImages(2) [image create photo -file "$images/Bit2Off.png"]
set bitOnImages(2) [image create photo -file "$images/Bit2On.png"]
set bitOffImages(1) [image create photo -file "$images/Bit1Off.png"]
set bitOnImages(1) [image create photo -file "$images/Bit1On.png"]
set bitOffImages(0) [image create photo -file "$images/Bit0Off.png"]
set bitOnImages(0) [image create photo -file "$images/Bit0On.png"]

#Frequency Settings for PWM
set pwmDuty 0
set pwmFrequency 1

#Interrupt Images
set IntOnImage [image create photo -file "$images/Inton.gif"]
set IntOffImage [image create photo -file "$images/Intoff.gif"]

#Input value
set inValue 0

set frequencyDisplay "? Hz"

set freqSliderRange 300
set sliderMode "log"
set minFrequencyLimit 1
set maxFrequencyLimit 125000
set minFrequency 1
set maxFrequency 125000
set defaultFrequency 1000




#---=== Export Public Procedures ===---
namespace export setDigioPath
namespace export getDigioPath
namespace export buildDigio

}

#---=== Procedures ===---
proc ::digio::setDigioPath {digioPath} {
	variable digio
	
	#Frame for Digital I/O Controls
	labelframe $digioPath.frame	\
		-relief groove	\
		-borderwidth 2	\
		-text "Digital I/O"	\
		-font {-weight bold -size -12}
	pack $digioPath.frame
	set digio(path) $digioPath.frame
}

proc ::digio::getDigioPath {} {
	variable digio
	
	return $digio(path)
}

proc ::digio::buildDigio {} {

	set digioPath [getDigioPath]
	
	#Digital Ouptut Controls
	labelframe $digioPath.out	\
		-relief groove	\
		-borderwidth 2	\
		-text "Digital Outputs"	\
		-font {-weight bold -size -12}

	for {set i 0} {$i < 8} { incr i} {
		button $digioPath.out.$i	\
			-image $::digio::bitOffImages($i)	\
			-command "::digio::toggleOutBit $i"
	}

	grid $digioPath.out.7 -row 1 -column 0 -pady 2
	grid $digioPath.out.6 -row 1 -column 1
	grid $digioPath.out.5 -row 1 -column 2
	grid $digioPath.out.4 -row 1 -column 3
	grid $digioPath.out.3 -row 1 -column 4
	grid $digioPath.out.2 -row 1 -column 5
	grid $digioPath.out.1 -row 1 -column 6
	grid $digioPath.out.0 -row 1 -column 7
	
	#Digital Input Indicators
	labelframe $digioPath.in	\
		-relief groove	\
		-borderwidth 2	\
		-text "Digital Inputs"	\
		-font {-weight bold -size -12}
		
	for {set i 0} {$i <8} {incr i} {
		label $digioPath.in.$i	\
			-image $::digio::bitOffImages($i)
	}

	grid $digioPath.in.7 -row 1 -column 0 -pady 4
	grid $digioPath.in.6 -row 1 -column 1
	grid $digioPath.in.5 -row 1 -column 2
	grid $digioPath.in.4 -row 1 -column 3
	grid $digioPath.in.3 -row 1 -column 4
	grid $digioPath.in.2 -row 1 -column 5
	grid $digioPath.in.1 -row 1 -column 6
	grid $digioPath.in.0 -row 1 -column 7

	#PWM Control
	labelframe $digioPath.pwm	\
		-relief groove	\
		-borderwidth 2	\
		-text "Pulse Output"	\
		-font {-weight bold -size -12}
	
	

	#canvas $digioPath.pwm.display	\
	#	-width 70	\
	#	-height 15	\
	#	-background white

	labelframe $digioPath.pwm.duty	\
		-relief raised	\
		-borderwidth 2	\
		-text "Duty Cycle"

	scale $digioPath.pwm.duty.slider\
		-from 0		\
		-to 99			\
		-variable digio::pwmDuty	\
		-orient horizontal	\
		-showvalue 1	\
		-length 240	\
		-tickinterval 0	\
		-resolution 1	\
		-command ::digio::updateDuty
		
	pack $digioPath.pwm.duty.slider
	
	labelframe $digioPath.pwm.freq	\
		-relief raised	\
		-text "Frequency"
		
	button $digioPath.pwm.freq.display	\
		-relief sunken	\
		-borderwidth 3	\
		-textvariable digio::frequencyDisplay	\
		-font {-weight bold -size -12}	\
		-background black	\
		-foreground red	\
		-width 10	\
		-command digio::setFrequency
		
	scale $digioPath.pwm.freq.slider	\
		-from 1	\
		-to $digio::freqSliderRange	\
		-variable digio::frequencyPosition	\
		-orient horizontal	\
		-tickinterval 0	\
		-resolution 1	\
		-showvalue 0	\
		-length $digio::freqSliderRange		\
		-command digio::adjustFrequency
		
	button $digioPath.pwm.freq.bottomValue	\
		-textvariable digio::minFrequency	\
		-width 8	\
		-command digio::setMinFrequency
		
	button $digioPath.pwm.freq.topValue	\
		-textvariable digio::maxFrequency	\
		-width 8	\
		-command digio::setMaxFrequency
	
	grid $digioPath.pwm.freq.display -row 0 -column 1
	grid $digioPath.pwm.freq.bottomValue -row 1 -column 0
	grid $digioPath.pwm.freq.slider -row 1 -column 1
	grid $digioPath.pwm.freq.topValue -row 1 -column 2
	
	#grid $digioPath.pwm.display -row 0 -column 1
	grid $digioPath.pwm.duty -row 1 -column 0 -columnspan 3
	grid $digioPath.pwm.freq -row 2 -column 0 -columnspan 3

	grid $digioPath.in -row 0 -column 0  -ipady 3 -padx 2
	grid $digioPath.out -row 1 -column 0 -ipady 3 -padx 2
	grid $digioPath.pwm -row 0 -column 1 -padx 2 -rowspan 2

}

# Toggle Output Bit
#----------------------
#This procedure is called when the user clicks on an output bit to change it's state.
proc ::digio::toggleOutBit {bitNum} {
	variable digout
	variable bitOnImages
	variable bitOffImages
	
	set digPath [getDigioPath]

	if {$digout($bitNum)==1} {
		set digout($bitNum) 0
		$digPath.out.$bitNum configure -image $bitOffImages($bitNum)
	} else {
		set digout($bitNum) 1
		$digPath.out.$bitNum configure -image $bitOnImages($bitNum)
	}
	
	::digio::updateDigio

}

# Update Digital I/O Hardware Registers
#-----------------------------------------------
# This procedures sends commands to the instrument to update the digital
# I/O registers.
proc ::digio::updateDigio {} {
	variable digout
		
	set digReg 0
	
	set digReg [expr {$digReg+$digout(0)*1}]
	set digReg [expr {$digReg+$digout(1)*2}]
	set digReg [expr {$digReg+$digout(2)*4}]
	set digReg [expr {$digReg+$digout(3)*8}]
	set digReg [expr {$digReg+$digout(4)*16}]
	set digReg [expr {$digReg+$digout(5)*32}]
	set digReg [expr {$digReg+$digout(6)*64}]
	set digReg [expr {$digReg+$digout(7)*128}]
	
	sendCommand "O $digReg"
}

# Update PWM Settings
#-------------------------
# This procedure services the PWM slider.  It updates the PWM display and
# sends commands to the hardware to update the PWM output.
proc ::digio::updateDuty {sliderArg} {
	#variable pwmDuty

	#Calculate the duty cycle (8-bit)
	#set pwmDuty [expr {round($sliderArg/100.0*255)}]
	
	digio::updatePWM
	
	#sendCommand "D D $dutyCycle"
	
	#Update the PWM Display
#	set digioPath [getDigioPath]
	
## 	$digioPath.pwm.display delete pwmTag
 # 	
 # 	set plotData {}
 # 	
 # 	puts $sliderArg
 ##

## 	lappend plotData 3
 # 	lappend plotData 12
 # 
 # 	for {set i 0} {$i < 3} {incr i} {
 # 		if {$sliderArg > 0} {
 # 			lappend plotData [expr {3+20*$i}]
 # 			lappend plotData 2
 # 			set temp [expr {($sliderArg/100.0)*20+(3+20*$i)}]
 # 			lappend plotData $temp
 # 			lappend plotData 2
 # 			if {$sliderArg < 100} {
 # 				lappend plotData $temp
 # 				lappend plotData 12
 # 				lappend plotData [expr {3+20*($i+1)}]
 # 				lappend plotData 12
 # 			}
 # 		}
 # 	}
 # 	lappend plotData 63
 # 	lappend plotData 12
 # 	
 # 	$digioPath.pwm.display create line	\
 # 		$plotData	\
 # 		-tag pwmTag	\
 # 		-fill black		\
 # 		-width 1
 ##

}

proc ::digio::updateDigIn {value} {

	set digioPath [getDigioPath]
	
	set digio::inValue $value
	
	for {set i 7} {$i >=0} {set i [expr {$i-1}]} {
		if {$value >= [expr {pow(2,$i)}]} {
			$digioPath.in.$i configure -image $::digio::bitOnImages($i)
		} else {
			$digioPath.in.$i configure -image $::digio::bitOffImages($i)
		}
		set value [expr {$value%int(pow(2,$i))}]
	}
	
	
		
}

proc digio::adjustFrequency {sliderArg} {
	variable freqSliderRange
	variable minFrequency
	variable maxFrequency

	if {$digio::sliderMode == "log"} {
		#Logarithmic interpretation of slider position
		set logMin [expr {log10($minFrequency)}]
		set logMax [expr {log10($maxFrequency)}]
		set b $logMin
		set m [expr {($logMax-$logMin)/($freqSliderRange-1)}]
		set y [expr {$m*($sliderArg-1)+$b}]
		set frequency [expr {pow(10,$y)}]
		
	} else {
		#Linear interpretation of slider position
		set b $minFrequency
		set m [expr {($maxFrequency-$minFrequency)/($freqSliderRange-1)}]
		set y [expr {$m*($sliderArg-1)+$b}]
		set frequency $y
	}
	
	#Round to the nearest tenth of a hertz
	set digio::pwmFrequency [format "%.1f" $frequency]
	
	#Update the hardware with the new frequency
	digio::updatePWM
	
	#Update the frequency display
	set digio::frequencyDisplay "$digio::pwmFrequency Hz"
	

}

#Set Maximum Frequency
#---------------
#This procedure prompts the user for a new max frequency value.
#The frequency supplied by the user is checked to ensure that
#it is a valid number and a valid frequency setting.
proc digio::setMaxFrequency {} {
	variable minFrequency
	variable maxFrequency
	
	set newMax [Dialog_Prompt setMax "New Maximum Frequency:"]
	
	if {$newMax == ""} { return }
	
	if { [string is double -strict $newMax]} {
		if {$newMax > $minFrequency && $newMax <= $digio::maxFrequencyLimit} {
			set digio::maxFrequency [format "%.1f" $newMax]
			set digioPath [digio::getDigioPath]
			digio::adjustFrequency [$digioPath.pwm.freq.slider get] 
		} else {
			tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Invalid Frequency.\nMax frequency is $digio::maxFrequencyLimit\nMin frequency is $minFrequency"	\
			-type ok			\
			-icon warning
		}
	} else {
		tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Frequency must be a number\nbetween $digio::minFrequencyLimit and $digio::maxFrequencyLimit."	\
			-type ok			\
			-icon warning
		return
	}
}

#Set Minimum Frequency
#---------------
#This procedure prompts the user for a new min frequency value.
#The frequency supplied by the user is checked to ensure that
#it is a valid number and a valid frequency setting.
proc digio::setMinFrequency {} {
	variable maxFrequency

	set newMin [Dialog_Prompt setMin "New Minimum Frequency:"]
	
	if {$newMin == ""} {return}
	
	if { [string is double -strict $newMin] } {
		if { $newMin < $maxFrequency && $newMin >= $digio::minFrequencyLimit} {
			set digio::minFrequency [format "%.1f" $newMin]
			set digioPath [digio::getDigioPath]
			digio::adjustFrequency [$digioPath.pwm.freq.slider get]
		} else {
			tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Invalid Frequency.\nMin frequency is $digio::minFrequencyLimit\nMax frequency is $maxFrequency"	\
			-type ok			\
			-icon warning
		}
	} else {
		tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Frequency must be a number\nbetween $digio::minFrequencyLimit and $digio::maxFrequencyLimit."	\
			-type ok			\
			-icon warning
		return
	}
}

# Manually Set Frequency
#---------------------------
# This procedure is called when the user wants to manually set the waveform generator
# output frequency.  It presents the user with a dialog box where they can enter
# the desired output frequency.
proc digio::setFrequency {} {
	variable minFrequencyLimit
	variable maxFrequencyLimit
	variable frequencyDisplay
	variable pwmFrequency
	
	#Dialog box for user to enter the new frequency
	set newFreq [Dialog_Prompt newF "New Frequency:"]
	
	if {$newFreq == ""} {return}
	
	#Make sure that we got a valid frequency setting
	if { [string is double -strict $newFreq] } {
		if { $newFreq >= $minFrequencyLimit && $newFreq <= $maxFrequencyLimit} {
			set frequencyDisplay [format "%.1f" $newFreq]
			set pwmFrequency $frequencyDisplay
			digio::updatePWM
			set frequencyDisplay "$frequencyDisplay Hz"
		} else {
			tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Frequency out of range: $minFrequencyLimit to $maxFrequencyLimit"	\
			-type ok			\
			-icon warning
		}
	} else {
		tk_messageBox	\
			-title "Invalid Frequency"	\
			-default ok		\
			-message "Frequency must be a number\nbetween $minFrequencyLimit and $maxFrequencyLimit"	\
			-type ok			\
			-icon warning
		return
	}
	

}

proc digio::updatePWM {} {
	variable pwmFrequency
	variable pwmDuty

	#Determine which prescaler is necessary for this PWM frequency
	if {$pwmFrequency > 489} {
		#Prescaler = 1
		set prescaler 1
		set clockFreq 32.0E6
	} elseif {$pwmFrequency > 245} {
		#Prescaler = 2
		set prescaler 2
		set clockFreq 16.0E6
	} elseif {$pwmFrequency > 125} {
		#Prescaler = 4
		set prescaler 3
		set clockFreq 8.0E6
	} elseif {$pwmFrequency > 65} {
		#Prescaler = 8
		set prescaler 4
		set clockFreq 4.0E6
	} elseif {$pwmFrequency > 8}  {
		#Prescaler = 64
		set prescaler 5
		set clockFreq 500.0E3
	} elseif {$pwmFrequency > 2} {
		#Prescaler = 256
		set prescaler 6
		set clockFreq 125.0E3
	} else {
		#Prescaler = 1024
		set prescaler 7
		set clockFreq 31.25E3
	}
	
	#Calculate the period in clock counts
	set period [expr {round($clockFreq/$pwmFrequency)}]
	
	set duty [expr {round($pwmDuty/100.0*$period)}]
	
	#puts "Prescaler $prescaler"
	#puts "Period $period"
	#puts "Duty $duty"
	sendCommand "WS$prescaler"
	sendCommand "WP$period"
	sendCommand "WD$duty"


}
