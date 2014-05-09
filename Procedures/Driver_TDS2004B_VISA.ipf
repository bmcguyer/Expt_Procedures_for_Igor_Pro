#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0	// This File's Version	

//####[ Driver_TDS2004B_VISA ]##########################################
//	Bart McGuyer, Department of Physics, Princeton University 2008
//	Acknowledgements:  
// -- This code comes from work performed while I was a graduate student 
//		in the research group of Professor William Happer, and builds on 
//		some previous code from that group. 
//	
//	Procedure file to work with Tektronics TDS2004B oscilloscopes with VISA over USB, 
//	though should in general work with TDS1000 and TDS2000 series too.
//	Saves scope traces as waves Tek_Ch1, etc.
//	
//	Dependencies:  
//	-- DAQ_VISA v1.0 or above: visaSend and visaQuery.
//#include ":DAQ_VISA"
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com.
//	-- v1.1: 9/21/2009 - Cleaned up code, reorganized, and separated VISA code out of original file VISA_TDS2004B.  Added setupAvg, setupSample.
//	
//	Possible future work:
//	-- There might be trouble with getChan errors when a channel is not displayed -- issue with error checking?
//	-- Get reference waveforms too?
//	
//	Notes:
// -- Shares global variables and some function names with the other Tek driver files Driver_TDS1000 and Driver_TDS3000.
//	-- This code scales captured traces with preamble data, which avoids errors with a previous method.
//		Previous method (Happer group code) used channel queries to get scaling information, which 
//		works but causes inaccuracy (I've seen up to 20%???) for different Vpos,Vscale 
//		settings of the same signal.   For example: Look at a 1V signal for different Voffset and Vscale.  
//		For no Voffset and large Vscale, can get bad wavstats.  For Voffset s.t. Vscale is zoomed in far, get great agreement!   
//	
//	####[ Table of Contents ]####
//	Functions:						Description:
//		saveTek							Saves captured scope traces as new waves with a waveid, to work with Expt_Analysis
//		getChan_TDS2K					Saves a trace from the o-scope into a global variable
//		getTekCh1 to 4					Shortcut to get Ch1 to 4, assumes devname = "scope"
//		getTekAll_TDS2K				Shortcut to get all channels, assumes devname = "scope"
//		setupAvg_TDS2K					Sets up scope in average mode
//		setupSample_TDS2K				Sets up scope in sample mode		



//saveTek:  Saves captured scope traces as new waves with a waveid, to work with Expt_Analysis
Function saveTek()
	//Assumes Tek_Ch1 to 4 exist.  
	variable waveid = nextwave()
	string cmt
	
	//Prompt user for comment to describe the data
	Prompt cmt, "Comment for these wave(s):"
	DoPrompt "User Comment", cmt
	
	//Compile a wavenote string with useful information.  
	//NOTE:  this will overwrite the wavenote text from the scope capture, which is mostly useless anyways.  
	string wnote
	sprintf wnote, "date:%s;time:%s;cmd:recordData();", date(), time()
	wnote += "comment:" + cmt + ";"
	wnote += "dlabel:Scope (\\uV);"	//label y-axis as scope voltage (voltage)
	wnote += "xlabel:Scope (\\us);"	//label x-axis as scope time (seconds)
	
	//Duplicate waves and add new wavenotes
	Duplicate $("Tek_Ch1") $("TekCh1_" + num2istr(waveid))
	Note/K/NOCR $("TekCh1_"+num2istr(waveid)) wnote
	Duplicate $("Tek_Ch2") $("TekCh2_" + num2istr(waveid))
	Note/K/NOCR $("TekCh2_"+num2istr(waveid)) wnote
	Duplicate $("Tek_Ch3") $("TekCh3_" + num2istr(waveid))
	Note/K/NOCR $("TekCh3_"+num2istr(waveid)) wnote
	Duplicate $("Tek_Ch4") $("TekCh4_" + num2istr(waveid))
	Note/K/NOCR $("TekCh4_"+num2istr(waveid)) wnote
	
	//Display the data
	//shownum(waveid)
	
	//Report to history
	Print "-- Scope traces saved as wave(s) # " + num2istr(waveid) + "."
	Print "-- User comment for these wave(s):\t" + cmt + "."
End

//Shortcut code to record scope traces
Function getTekAll_TDS2K()
	getChan_TDS2K(1)
	getChan_TDS2K(2)
	getChan_TDS2K(3)
	getChan_TDS2K(4)
End

//Shortcut code to record scope traces
Function getTekCh1()
	getChan_TDS2K("scope", 1)
End
Function getTekCh2()
	getChan_TDS2K("scope", 2)
End
Function getTekCh3()
	getChan_TDS2K("scope", 3)
End
Function getTekCh4()
	getChan_TDS2K("scope", 4)
End

//setupAvg_TDS1K:  Sets up scope in average mode
Function setupAvg_TDS2K(devname, avg)
	string devname				//device name for GPIB calls
	variable avg				//number of averages, must be a power of 2
	
	gpibSend(devname, "ACQUIRE:STATE OFF")				//stop taking data
	gpibSend(devname, "ACQUIRE:NUMAVG " + num2istr(avg))	//set number of averages in average mode
	gpibSend(devname, "ACQUIRE:MODE AVERAGE")			//set to average mode
	gpibSend(devname, "ACQUIRE:STATE ON")					//start taking data
End

//setupSample_TDS1K:  Sets up scope in sample mode
Function setupSample_TDS2K(devname)
	string devname				//device name for GPIB calls
	
	gpibSend(devname, "ACQUIRE:STATE OFF")				//stop taking data
	gpibSend(devname, "ACQUIRE:MODE SAMPLE")			//set to sample mode
	gpibSend(devname, "ACQUIRE:STATE ON")					//start taking data
End

//getChan_TDS2K:  Saves a trace from the o-scope into a global variable
Function getChan_TDS2K(chan)
	variable chan		//which scope channel to record
	
	//GLOBAL Variables 
	NVAR VISA_defaultRM		//global VISA session variable!
	NVAR VISA_instr				//global session id for USB scope!
	
	//Create local variables (quirk of VISA XOP)
	Variable defaultRM = VISA_defaultRM
	Variable instr = VISA_instr
	
	//Error Catch:
	If((VISA_defaultRM == -1)||(VISA_instr == -1))
		Print "#### Error:  VISA global variables indicate no session or instrument!"
		abort
	endif
	If((chan != 1) && (chan != 2) && (chan != 3) && (chan != 4))
		Print "#### ERROR during getChan_TDS2K:  Invalid channel selection = " + num2istr(chan) + "!"
		abort
	endif
	
	//Print visaQuery(instr, "*IDN?")	//test communication
	
	//Check to see if the trace is displayed:
	if(!str2num(visaQuery(instr, "SELECT:CH" + num2istr(chan) + "?")))
		Print "#### ERROR during getChan_TDS2K:  Channel " + num2istr(chan) + " not displayed!"
		abort
	endif
	
	//Get non-data information, not from the pre-amble.
	variable RecLength = str2num(visaQuery(instr,"HOR:RECORDLENGTH?"))	//Get number of horizontal axis datapoints (either 500 or 10000)
	variable HorizScale = str2num(visaQuery(instr,"HOR:MAIN:SCALE?"))
	
	//Setup scope to transfer waveform
	visaSend(instr,"DATA:SOURCE CH" + num2istr(chan))	// Start reading Ch 1
	visaSend(instr,"DATA:ENCDG RIBINARY")			// Specify output format of scope -- binary, signed integer
	visaSend(instr,"DATA:WIDTH 2")					// ibid -- 16 bits/point
	visaSend(instr,"DATA:START 1")					// Start at first point in trace
	visaSend(instr,"DATA:STOP " + num2istr(RecLength))	// End at last point in trace
	visaSend(instr,"HEADER OFF")						// B. Patton says "STFU!"
	
	// Get non-data information from pre-amble (doesn't read full preamble!!!!)
	string waveformInfo = visaQuery(instr,"WFMPRE:WFID?")			//Reads description of the trace
	variable Yoff = str2num(visaQuery(instr,"WFMPRE:YOFF?"))		// Read the vertical position (divs)
	variable Ymult = str2num(visaQuery(instr,"WFMPRE:YMULT?"))	// Read the vertical scale factor (V/divs)
	variable Yzero = str2num(visaQuery(instr,"WFMPRE:YZERO?"))	// Read the vertical offset (volts)
	
	//Setup Wave and horizontal axis
	string name = "Tek_Ch" + num2istr(chan)	// Assemble name of wave to store data
	Make/D/O/N=(RecLength) $name = NaN			// Make wave to store data, DOUBLE PRECISION!
	WAVE data = $name									// Setup string handle for data wave
	SetScale/P x 0, (HorizScale * 10 / RecLength), data	// Set horizontal scale (units = s, but don't label here)
	SetScale d -Inf,Inf, data				// Set vertical scale (units = V, but don't label here)
	
	//Transfer Waveform from Oscilloscope
	string dummy
	visaSend(instr, "CURVE?")						// Request the data!
	visaRead/N=(2+ceil(log(RecLength+0.5))) instr, dummy	// Read the preamble (to ignore it) of length 5 for 500, 7 for 10000 points
	visaReadBinaryWave/TYPE=(0x10) instr, data		// Ask for data stream, no "B" flag b/c RIBINARY indicates most-significant-byte first.  0x10 = 2 bytes/point.
	visaRead instr, dummy							// Read post-amble, just to get rid of it.
	
	//Convert data to volts using pre-amble data:  (PREFERRED METHOD!)
	data -= Yoff
	data *= Ymult
	data += Yzero
	
	//Save waveform information (coupling, gain, etc.) to wavenote and print it to history
	Note/K data; Note data, waveformInfo	//Save info as wavenote to data wave
	Print "-- Trace captured: " + waveformInfo	
End