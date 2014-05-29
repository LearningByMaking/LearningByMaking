#File: firmware.tcl
#Syscomp Electronic Design Ltd.
#www.syscompdesign.com
#JG
#Copyright 2012 Syscomp Electronic Design

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

package provide firmware 1.0

namespace eval firmware {

#---=== Global Variables ===---
set currentRev "V1.2.1"

set receivedData {}
set status startup
set enterStatus 0

set firmwareHandle stdout
set serialCheck -1
set afterHandle null

set flashSize 65536
set pageSize 512
set blockSize 512

set data {}
set flashVerify {}
set device2Data {}
set device2Verify {}
set device2FlashSize [expr {208*264}]

set crcPoly 0x0080001B

}

#Show Firmware GUI
#----------------------
#This procedure builds the firmware upgrade dialog box or
#restores it if it has already been created.
proc firmware::showFirmware {} {

	if {![winfo exists .firmware]} {
	
		toplevel .firmware
		wm title .firmware "Firmware Upgrade"
		
		frame .firmware.manual	\
			-relief groove	\
			-borderwidth 2
			
		button .firmware.manual.start	\
			-text "Start upgrade"	\
			-command {.firmware.manual.start configure -state disabled; firmware::firmwareUpgrade}
			
		grid .firmware.manual.start
		
		text  .firmware.log	\
			-width 80		\
			-height 15		\
			-undo 1
			
		grid .firmware.manual -row 0
		grid .firmware.log -row 1

		wm iconify .
		raise .firmware
		focus .firmware
		grab .firmware
			
	} else {
		wm deiconify .firmware
		raise .firmware
		focus .firmware
	}
}

#Firmware Upgrade
#---------------------
#This is the main firmware upgrade procedure.  This procedure is called to
#perform a firmware upgrade.
proc firmware::firmwareUpgrade {} {

	#Open the serial port for our own evil purposes
	if {![firmware::openSerialPort]} {
		firmware::addLog "Unable to open serial port for firmware upgrade."
		return
	}
	
	#See if we need to enter the bootloader
	if {![string match "*CGM101BOOT*" $usbSerial::firmwareIdent]} {
		set firmware::status enterBootloader
		puts "Entering bootloader..."
		sendByte "*"
		sendByte "\n"
		set firmware::afterHandle [after 5000 {set firmware::status timeout}]
		vwait firmware::status
		after cancel $firmware::afterHandle
		if {$firmware::status != "enteredBootloader"} {
			firmware::addLog "Unable to enter firmware upgrade mode."
			return
		}
	}
	
	#Open the HEX file
	firmware::addLog "Opening firmware file #1..."
	if {![firmware::openHexFile "./Firmware/Device1.hex"]} {
		firmware::closeSerialPort
		firmware::addLog "Failed to open firmware file #1"
		return
	} else {
		firmware::addLog "Reading file complete."
	}
	
	#Erase the device
	firmware::addLog "Erasing device #1..."
	if {[firmware::eraseDevice1]} {
		firmware::addLog "Erase complete."
	} else {
		firmware::addLog "Erase failed."
		firmware::closeSerialPort
		return
	}
	
	#Program the Flash
	firmware::addLog "Programming device #1..."
	if {![firmware::writeFlash]} {
		firmware::addLog "Flash programming failed."
		firmware::closeSerialPort
		return
	} else {
		firmware::addLog "Flash programming complete."
	}
	
	#Verify the Flash
	firmware::addLog "Verifying device #1..."
	if {![firmware::verifyFlash]} {
		firmware::addLog "Verify failed."
		firmware::closeSerialPort
		return
	} else {
		firmware::addLog "Flash verification complete."
	}
	
	#Open the hex file
## 	firmware::addLog "Opening firmware file #2..."
 # 	if {![firmware::openDevice2File "./Firmware/Device2.hex"]} {
 # 		firmware::closeSerialPort
 # 		return
 # 	} else {
 # 		firmware::addLog "Reading file complete"
 # 	}
 ##
	
	#Program the device
## 	firmware::addLog "Programming device #2..."
 # 	if {![firmware::device2Write]} {
 # 		firmware::addLog "Programming failed."
 # 		firmware::closeSerialPort
 # 		return
 # 	} else {
 # 		firmware::addLog "Programming Complete."
 # 	}
 ##
	
	#Verify the device
## 	firmware::addLog "Verifying device #2..."
 # 	if {![firmware::verifyDevice2]} {
 # 		firmware::addLog "Verify failed"
 # 		firmware::closeSerialPort
 # 		return
 # 	} else {
 # 		firmware::addLog "Verify device #2 complete."
 # 	}
 ##
	
	#Install the new firmware
	firmware::addLog "Completing firmware upgrade..."
	if {![firmware::installFirmware]} {
		firmware::addLog "Final installation failed!"
		firmware::closeSerialPort
		return
	} else {
		firmware::addLog "Firmware upgrade complete!"
		firmware::sendByte E
	}
	
	#Clean up so the main application can use the port
	
	firmware::closeSerialPort
	
	tk_messageBox	\
		-message "Firmware upgrade complete.\nPlease cycle power on the device and\npress OK to continue..."	\
		-default ok	\
		-type ok
		
	wm deiconify .
	raise .
	focus .
	destroy .firmware
	
	usbSerial::openSerialPort

}

proc firmware::eraseDevice1 {} {
	set firmware::status waiting
	after 750 firmware::insertDot
	firmware::sendByte e
	set firmware::status erasing
	set firmware::afterHandle [after 10000 {set firmware::status timeout}]
	vwait firmware::status
	after cancel $firmware::afterHandle
	if {$firmware::status != "erased"} {
		return 0
	} else {
		return 1
	}
}

proc firmware::setupFileEvent {} {
	
	fileevent $firmware::firmwareHandle readable {
		firmware::processResponse
	}
	
}

proc firmware::processResponse {} {

	#Read in all available data from the serial port
	set incomingData [read $firmware::firmwareHandle]
	
	#Convert the data bytes into signed integers
	if { [llength {$incomingData}] > 0 } {
		binary scan $incomingData c* signed
		#Convert the bytes into unsigned integers (0-255)
		foreach byte $signed {
			lappend firmware::receivedData [lindex $::usbSerial::cvt [expr {$byte & 255}]]
		}
	}
	
	#See if we have data in the buffer to process
	if {[llength $firmware::receivedData] > 0} {
		set responseType [lindex $firmware::receivedData 0]
		set responseType [format %c $responseType]
	} else {
		return
	}
		
	#Get the total length of the message (number of bytes)
	set responseLength [llength $firmware::receivedData]
	
	#Process the message based on it's message type
	switch $responseType {
		"E" {
			puts "Erase Complete"
			set firmware::status "erased"
		} "A" {
			if {$responseLength < 3} {
				puts "Waiting for more data!"
				return
			}
			set address [expr {([lindex $firmware::receivedData 1] << 8) + [lindex $firmware::receivedData 2]}]
			#puts "Return address is $address"
			set firmware::status [list "OK" $address]
		} "F" {
			set firmware::status flashProgrammed
		} "R" {
			if {$responseLength < 3} {
				puts "Waiting for more data"
				return
			}
			set highByte [lindex $firmware::receivedData 1]
			set lowByte [lindex $firmware::receivedData 2]
			set firmware::status [list "R" $highByte $lowByte]
		} "S" {
			if {$responseLength < 2} {
				puts "Waiting for more data"
				return
			}
			set status [lindex $firmware::receivedData 1]
			puts "Status: $status ([format %x $status])"
		} "I" {
			if {$responseLength < 5} {
				return
			}
			set manufacturer [lindex $firmware::receivedData 1]
			set family [lindex $firmware::receivedData 2]
			set device [lindex $firmware::receivedData 3]
			set extended [lindex $firmware::receivedData 4]
			puts "Info: $manufacturer ([format %x $manufacturer]) $family ([format %x $family]) $device ([format %x $device]) $extended ([format %x $extended])"
		} "r" {
			if {$responseLength < 265} {
				puts "Waiting for more bytes"
				return
			}
			set firmware::status [list "FROK" [lrange $firmware::receivedData 1 end]]
			puts "Received full page record"
		} "w" {
			set firmware::status "WOK"
		} "C" {
			if {$responseLength < 4} {
				puts "Waiting for more bytes"
				return
			}
			set crcFlash [expr {[lindex $firmware::receivedData 1]*65536 + 256*[lindex $firmware::receivedData 2]+[lindex $firmware::receivedData 3]}]
			puts "Device CRC is $crcFlash"
			set firmware::status [list "CRC" $crcFlash]
		} "c" {
			if {$responseLength < 4} {
				puts "Waiting for more bytes"
				return
			}
			set storedFlash [expr {[lindex $firmware::receivedData 1]*65536 + 256*[lindex $firmware::receivedData 2]+[lindex $firmware::receivedData 3]}]
			puts "Stored CRC is $storedFlash"
			set firmware::status [list "ERC" $storedFlash]
		} "g" {
			if {$responseLength < [expr {$firmware::flashSize+1}]} {
				.firmware.log delete "insert linestart" "insert lineend"
				firmware::addChar "[expr {round($responseLength*1.0/$firmware::flashSize*100)}]%"
				puts "Waiting for more bytes.  Received $responseLength bytes so far."
				return
			}
			set firmware::status [list "gOK" [lrange $firmware::receivedData 1 end]]
			puts "Received full flash record"
		} "B" {
			if {$responseLength < 6} {
				puts "Waiting for full bootloader challenge"
				return
			}
			set response [expr {[lindex $firmware::receivedData 1]+[lindex $firmware::receivedData 2]+[lindex $firmware::receivedData 3]}]
			puts "Responding to challenge with $response"
			firmware::sendByte [format "%c" $response]
			firmware::sendByte "\n"
			set firmware::enterStatus 1
		} "b" {
			puts "Received confirmation from bootloader"
			if {$firmware::enterStatus} {
				set firmware::enterStatus 0
				set firmware::status enteredBootloader
			}
		} default {
			#We received an unknown message type
			puts "Unknown response: $responseType"
			set temp [llength $firmware::receivedData]
			puts "Buffer length $temp"
			puts $firmware::receivedData
			set firmware::receivedData {}
		}
	}	
	
	set firmware::receivedData {}

}

proc firmware::addLog {logText} {

	.firmware.log insert end "$logText\n"
	.firmware.log yview moveto 1
}

proc firmware::addChar {char} {

	.firmware.log insert end $char
	.firmware.log yview moveto 1
}

proc firmware::insertDot {} {
	
	if {$firmware::status == "waiting"} {
		.firmware.log insert end "."
	} else {
		return
	}
	
	if {$firmware::status == "waiting"} {
		after 750 firmware::insertDot
	}
}

proc firmware::openSerialPort {} {

	#Make sure the serial port is available for firmware upgrade only
	usbSerial::closeSerialPort

	if {[catch {set firmware::firmwareHandle [open $usbSerial::serialPort r+]} result]} {
		firmware::addLog "Unable to open serial port for upgrade:"
		firmware::addLog "$result"
		firmware::addLog "Check serial settings in the Hardware-->Port Settings Menu"
	} else {
		fconfigure $firmware::firmwareHandle \
			-mode 9600,n,8,1	\
			-blocking 0			\
			-buffering line 		\
			-encoding binary		\
			-translation {lf binary}	\
			-eofchar {{} {}}
		
		#We are now going to query the device.
		#We set up  and intermediate fileevent handler to deal with 
		#identification data received from the instrument
		fileevent $firmware::firmwareHandle readable {
			set incomingData [gets $firmware::firmwareHandle]
			puts "incomingData: $incomingData"
			if { [string match "\*CGM101BOOT*" $incomingData] == 1} {
				set firmware::serialCheck firmwareOnly
				set usbSerial::firmwareIdent $incomingData
			} elseif {[string match "*Mini*" $incomingData]} {
				set firmware::serialCheck firmwareUpgrade
				set usbSerial::firmwareIdent $incomingData
			} else {
				puts "No match"
			}
		}
		puts "Querying device..."
		after 500
		set junk [read $firmware::firmwareHandle]
		sendByte i
		sendByte "\n"
		
		#Wait for a response from the device
		set firmware::serialCheck waiting
		after 4000 {set firmware::serialCheck timeout}
		vwait firmware::serialCheck
		
		#Check to see if we found the device...
		if {($firmware::serialCheck == "firmwareOnly")||($firmware::serialCheck=="firmwareUpgrade")} {
			puts "Connected - $firmware::serialCheck"
			firmware::addLog "Connected to firmware loader."
			firmware::setupFileEvent
			return 1
		} else {
			puts "Failed."
			firmware::addLog "ERROR: Unable to connect to firmware loader on $usbSerial::serialPort"
			firmware::closeSerialPort
			return 0
		}
	
	}

}

proc firmware::closeSerialPort {} {
	
	if {$firmware::firmwareHandle != "stdout"} {
		flush $firmware::firmwareHandle
		catch { [close $firmware::firmwareHandle]}
	}
}

proc firmware::sendByte {byte} {

	puts -nonewline $firmware::firmwareHandle $byte
	flush $firmware::firmwareHandle
}

proc firmware::openHexFile {hexFile} {
	
	if {[catch {set fileHandle [open $hexFile r]} result]} {
		firmware::addLog "Unable to open hex file: $hexFile"
		return 0
	} else {
		firmware::addLog "Open firmware file...complete."
	}
	
	set firmware::data {}
	for {set i 0} {$i < [expr {$firmware::flashSize*2}]} {incr i} {
		lappend firmware::data 255
	}
	
	set baseAddress 0
	set start $firmware::flashSize
	set end 0
	
	while {[gets $fileHandle line] >= 0} {
		
		set record [firmware::processRecord $line]
		if {$record==-1} {
			firmware::addLog "Failed to process hex file."
			close $fileHandle
			return 0
		}
		
		#Process record according to type
		switch [lindex $record 2] {
			0 {
				set offset [lindex $record 1]
				set length [lindex $record 0]
				set data [lindex $record 3]
				if {[expr {$baseAddress + $offset + $length}] > $firmware::flashSize} {
					firmware::addLog "HEX file defines data outside of buffer limits!"
					firmware::addLog "Offset was $offset"
					close $fileHandle
					return 0
				}
				#Copy the data into our main data buffer
				for {set dataPos 0} {$dataPos < $length} {incr dataPos} {
					lset firmware::data [expr {$baseAddress+$offset+$dataPos}] [lindex $data $dataPos]
				}
				#Update byte usage
				if {[expr {$baseAddress+$offset}]<$start} {
					set start [expr {$baseAddress+$offset}]
				}
				if {[expr {$baseAddress+$offset+$length-1}] > $end} {
					set end [expr {$baseAddress+$offset+$length-1}]
				}
			} 1 {
				firmware::addLog "Reading firmware file...complete." 
				close $fileHandle
				return 1
			}
		}
	
	
	}
	
	#We should never reach here
	firmware::addLog "ERROR: Premature end of file encountered!"
	return 0

}

proc firmware::calculateCRC {} {

	set crc 0

	for {set i 0} {$i < [expr {$firmware::flashSize*2}]} {set i [expr {$i+2}]} {
	
		set helpA [expr {$crc << 1}]
		set helpA [expr {$helpA&0x00FFFFFE}]
		set helpB [expr {$crc&(1<<23)}]
		if {$helpB > 0} {
			set helpB 0x00FFFFFF
		}
		
		set data [expr {[lindex $firmware::data [expr {$i+1}]]*256+[lindex $firmware::data $i]}]
		
		set crc [expr {($helpA^$data)^($helpB&$firmware::crcPoly)}]
		set crc [expr {$crc&0x00FFFFFF}]
	}
	
	return $crc

}

proc firmware::installFirmware {} {

	set fileCRC [calculateCRC]
	
	set firmware::status gettingDeviceCRC
	firmware::sendByte "C"
	#Wait for the data to arrive
	set firmware::afterHandle [after 5000 {set firmware::status timeout}]
	vwait firmware::status
	after cancel $firmware::afterHandle
	if {[lindex $firmware::status 0] != "CRC"} {
		firmware::addLog "Read CRC failed!"
		return 0
	} else {
		if {[lindex $firmware::status 1] != $fileCRC} {
			puts "CRC mismatch. File: $fileCRC Device: [lindex $firmware::status 1]"
			return 0
		} else {
			set deviceCRC [lindex $firmware::status 1]
			if {![firmware::setAddress 1021]} {
				puts "Unable to set address for CRC"
				return 0
			} else {
				firmware::sendByte D
				firmware::sendByte [format "%c" [expr {($fileCRC>>16)&0xFF}]]
				firmware::setAddress 1022
				firmware::sendByte D
				firmware::sendByte [format "%c" [expr {($fileCRC>>8)&0xFF}]]
				firmware::setAddress 1023
				firmware::sendByte D
				firmware::sendByte [format "%c" [expr {($fileCRC&0xFF)}]]
				
				set firmware::status gettingStoredCRC
				firmware::sendByte "c"
				set firmware::afterHandle [after 1000 {set firmware::status timeout}]
				vwait firmware::status
				after cancel $firmware::afterHandle
				if {[lindex $firmware::status 0]!="ERC"} {
					firmware::addLog "Read ERC failed!"
					return 0
				} else {
					return 1
				}
			}
		}
	}
	

}

proc firmware::processRecord {line} {
	#Line should be at least 11 characters long
	if {[string length $line] < 11} {
		firmware::addLog "Wrong HEX file format, missing fields!"
		firmware::addLog "Line from file was: $line"
		return -1
	}
	
	#Check format of line
	if {[string index $line 0] != ":"} {
		firmware::addLog "Wrong HEX file format, does not start with colon!"
		firmware::addLog "Line from file was: $line"
		close $fileHandle
		return -1
	}
	#Parse length, offset, and type
	set length [firmware::hexConvert [string range $line 1 2]]
	set offset [firmware::hexConvert [string range $line 3 6]]
	set type [firmware::hexConvert [string range $line 7 8]]
		
	#We know how long the record should be
	if {[string length $line] < [expr {11+$length*2}]} {
		firmware::addLog "Wrong HEX file format, missing fields!"
		firmware::addLog "Line from file was: $line"
		close $fileHandle
		return -1
	}
		
	#Process the checksum
	set checksum $length
	set checksum [expr {$checksum + (($offset >> 8) & 0xFF)}]
	set checksum [expr {$checksum + ($offset & 0xFF)}]
	set checksum [expr {$checksum + $type}]
		
	#Parse the data fields
	set data {}
	if {$length} {
		for {set recordPos 0} {$recordPos<$length} {incr recordPos} {
			set temp [firmware::hexConvert [string range $line [expr {9+$recordPos*2}] [expr {9+$recordPos*2+1}]]]
			set checksum [expr {$checksum+$temp}]
			lappend data $temp
		}
	}
		
	#Correct Checksum?
	set temp [firmware::hexConvert [string range $line [expr {9+$length*2}] [expr {9+$length*2+1}]]]
	set checksum [expr {$checksum + $temp}]
	if {[expr {$checksum%256}] != 0} {
		firmware::addLog "Wrong checksum for HEX record!"
		firmware::addLog "Line from file was $line"
		close $fileHandle
		return -1
	}
	
	set returnList {}
	lappend returnList $length
	lappend returnList $offset
	lappend returnList $type
	lappend returnList $data
	
	return $returnList

}

proc firmware::hexConvert {hex} {

	if {[string length $hex] == 0} {
		error "Cannot convert 0 length hex"
		return
	}
	if {[string length $hex] > 8} {
		error "Hex conversion overflow! Too many hex digits in string."
		return
	}
	
	set result 0
	for {set i 0} {$i < [string length $hex]} {incr i} {
		set char [string index $hex $i]
		if {[string is integer $char]} {
			set digit $char
		} elseif {($char=="a")||($char=="A")} {
			set digit 10
		} elseif {($char=="b")||($char=="B")} {
			set digit 11
		} elseif {($char=="c")||($char=="C")} {
			set digit 12
		} elseif {($char=="d")||($char=="D")} {
			set digit 13
		} elseif {($char=="e")||($char=="E")} {
			set digit 14
		} elseif {($char=="f")||($char=="F")} {
			set digit 15
		} else {
			error "Invalid hex digit found"
			return
		}
		set result [expr {$result*16 + $digit}]
	}
	return $result

}

proc firmware::writeFlash {} {

	set start 0
	set end $firmware::flashSize
	
	set address $start

	firmware::addChar "0%"
	
	while { [expr {$end-$address+1}] >= $firmware::blockSize} {
		puts "Address $address"
	
		set byteCount $firmware::blockSize
	
		#Set flash word address
		if {![firmware::setAddress [expr {$address>>1}]]} {
			firmware::addLog "ERROR: Programming flash failed"
			return 0
		}
		
		firmware::sendByte "B"
		set temp [expr {($byteCount>>8) & 0xFF}]
		firmware::sendByte [format "%c" $temp]
		set temp [expr {($byteCount & 0xFF)}]
		firmware::sendByte [format "%c" $temp]
		firmware::sendByte "F"
		
		set firmware::status programmingFlash
		while {$byteCount > 0} {
			firmware::sendByte [format "%c" [lindex $firmware::data $address]]
			incr address
			set byteCount [expr {$byteCount-1}]
		}
		
		set firmware::afterHandle [after 5000 {set firmware::status timeout}]
		vwait firmware::status
		after cancel $firmware::afterHandle
		if {$firmware::status == "flashProgrammed"} {
			.firmware.log delete "insert linestart" "insert lineend"
			firmware::addChar "[expr {round($address*1.0/$end*100)}]%"
		} else {
			firmware::addLog "ERROR: Programming flash failed!"
			return 0
		}
		
	}
	#Clean up the log
	.firmware.log delete "insert linestart" "insert lineend"
	firmware::addLog "100%"
	return 1

}

proc firmware::setAddress {address} {

		#Set up the address
		firmware::sendByte "A"
		#High Byte
		set temp [expr {($address >>8) & 0xFF}]
		firmware::sendByte [format "%c" $temp]
		#Low Byte
		set temp [expr {$address & 0xFF}]
		firmware::sendByte [format "%c" $temp]
		
		set firmware::status setAddress
		set firmware::afterHandle [after 5000 {set firmware::status timeout}]
		vwait firmware::status
		after cancel $firmware::afterHandle
		if {[lindex $firmware::status 0] != "OK"} {
			return 0
		} else {
			#puts $firmware::status
			set returnAddress [lindex $firmware::status 1]
			#puts "Address $address Returned Address $returnAddress"
			if {$returnAddress != $address} {
				firmware::addLog "Set address failed!"
				firmware::addLog "Address $address: $returnAddress"
				return 0
			} else {
				return 1
			}
		}

}

proc firmware::verifyFlash {} {

	set verifyData {}
	
	set address 0
	set size $firmware::flashSize
	set firmware::flashVerify {}
	
	firmware::addChar "0%"
	
	set firmware::status verifyingFlash
	
	firmware::setAddress $address
	firmware::sendByte g
	firmware::sendByte [format "%c" [expr {($size>>8)&0xFF}]]
	firmware::sendByte [format "%c" [expr {$size&0xFF}]]
	firmware::sendByte F
	
	#Wait for the data to arrive
	set firmware::afterHandle [after 5000 {set firmware::status timeout}]
	vwait firmware::status
	after cancel $firmware::afterHandle
	if {[lindex $firmware::status 0] != "gOK"} {
		firmware::addChar "\n"
		firmware::addLog "Flash verify failed"
		return 0
	} else {
		.firmware.log delete "insert linestart" "insert lineend"
		firmware::addLog "100%"
		foreach byte [lindex $firmware::status 1] {
			lappend firmware::flashVerify $byte
		}
	}
	
	set index 0
	foreach byte [lrange $firmware::data 0 65535] {
		if {$byte != [lindex $firmware::flashVerify $index]} {
			firmware::addLog "Verify failed at byte $index"
			return 0
		}
		incr index
	}
	
	firmware::addLog "Verify complete."
	return 1

}

proc firmware::device2Read {} {

	#Create a holder for the 
	set firmware::device2Verify {}

	firmware::addChar "0%"

	set pageAddress 0

	while {$pageAddress < 208} {
	
		#Initiate the read command
		set firmware::status readingFlash
		firmware::sendByte "v"
		#Send the address
		firmware::sendByte [format "%c" [expr {($pageAddress>>8) & 0xFF}]]
		firmware::sendByte [format "%c" [expr {($pageAddress) & 0xFF}]]
	
		#Wait for the data to arrive
		set firmware::afterHandle [after 5000 {set firmware::status timeout}]
		vwait firmware::status
		after cancel $firmware::afterHandle
		if {[lindex $firmware::status 0] != "FROK"} {
			firmware::addLog "Device 2 Flash Read failed at address $pageAddress"
			return 0
		} else {
			foreach byte [lindex $firmware::status 1] {
				lappend firmware::device2Verify $byte
			}
		}
		
		incr pageAddress
		
		.firmware.log delete "insert linestart" "insert lineend"
		firmware::addChar "[expr {round($pageAddress*1.0/208*100)}]%"
	}
	
	.firmware.log delete "insert linestart" "insert lineend"
	firmware::addLog "100%"
	firmware::addLog "Device 2 Flash Read Complete"

	if {[llength $firmware::device2Verify] != $firmware::device2FlashSize} {
		firmware::addLog "Device 2 Flash Read too short!"
		puts "Device 2 Flash Read too short!"
		return 0
	}

	return 1

}

proc firmware::openDevice2File {hexFile} {

	if {[catch {set fileHandle [open $hexFile r]} result]} {
		firmware::addLog "Unable to open hex file: $hexFile"
		return 0
	} else {
		firmware::addLog "Open firmware file...complete."
	}
	
	set firmware::device2Data {}
	for {set i 0} {$i < $firmware::device2FlashSize} {incr i} {
		lappend firmware::device2Data 255
	}
	
	set baseAddress 0
	set start $firmware::flashSize
	set end 0
	
	while {[gets $fileHandle line] >= 0} {
		
		set record [firmware::processRecord $line]
		if {$record==-1} {
			firmware::addLog "Failed to process hex file."
			close $fileHandle
			return 0
		}
		
		#Process record according to type
		switch [lindex $record 2] {
			0 {
				set offset [lindex $record 1]
				set length [lindex $record 0]
				set data [lindex $record 3]
				if {[expr {$baseAddress + $offset + $length}] > $firmware::device2FlashSize} {
					firmware::addLog "HEX file defines data outside of buffer limits!"
					firmware::addLog "Offset was $offset"
					close $fileHandle
					return 0
				}
				#Copy the data into our main data buffer
				for {set dataPos 0} {$dataPos < $length} {incr dataPos} {
					lset firmware::device2Data [expr {$baseAddress+$offset+$dataPos}] [lindex $data $dataPos]
				}
				#Update byte usage
				if {[expr {$baseAddress+$offset}]<$start} {
					set start [expr {$baseAddress+$offset}]
				}
				if {[expr {$baseAddress+$offset+$length-1}] > $end} {
					set end [expr {$baseAddress+$offset+$length-1}]
				}
			} 1 {
				firmware::addLog "Reading firmware file...complete." 
				close $fileHandle
				return 1
			}
		}
	
	
	}
	
	#We should never reach here
	firmware::addLog "ERROR: Premature end of file encountered!"
	return 0

}

proc firmware::device2Write {} {

	set pageAddress 0
	set byteAddress 0
	
	firmware::addLog "Writing to Device 2..."
	
	firmware::addChar "0%"
	
	for {set pageAddress 0} {$pageAddress < 208} {incr pageAddress} {
	
		#Fill the buffer
		set firmware::status writingBuffer
		firmware::sendByte "w"
		firmware::sendByte [format "%c" [expr {($pageAddress>>8) & 0xFF}]]
		firmware::sendByte [format "%c" [expr {($pageAddress & 0xFF)}]]
		for {set byteAddress 0} {$byteAddress < 264} {incr byteAddress} {
			firmware::sendByte [format "%c" [lindex $firmware::device2Data [expr {$pageAddress*264+$byteAddress}]]]
		}
		set firmware::afterHandle [after 5000 {set firmware::status timeout}]
		vwait firmware::status
		after cancel $firmware::afterHandle
		if { $firmware::status != "WOK"} {
			firmware::addLog ""
			firmware::addLog "Device 2 flash write failed at address $pageAddress"
			return 0
		}
		
		.firmware.log delete "insert linestart" "insert lineend"
		firmware::addChar "[expr {round($pageAddress*1.0/208*100)}]%"
	
	}
	
	.firmware.log delete "insert linestart" "insert lineend"
	firmware::addLog "100%"
	firmware::addLog "Writing to Device 2 complete."
	
	return 1
	
}

proc firmware::verifyDevice2 {} {

	if {![firmware::device2Read]} {
		return 0
	}

	set index 0
	
	foreach byte $firmware::device2Data {
		if {$byte != [lindex $firmware::device2Verify $index]} {
			firmware::addLog "Verify failed at byte $index"
			return 0
		}
		incr index
	}
	
	firmware::addLog "Verify complete."
	return 1

}

proc firmware::checkFirmware {} {

	if {[lindex $usbSerial::firmwareIdent 3] == $firmware::currentRev} {
		return 1
	} else {
		puts "Firmware upgrade available.  Current [lindex $usbSerial::firmwareIdent 4], available $firmware::currentRev"
		return 0
	}
}
