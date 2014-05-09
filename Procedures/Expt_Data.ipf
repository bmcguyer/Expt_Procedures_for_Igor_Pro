#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0	// This File's Version

//##[ WARNING! ]########################################################	
//	This procedure file is customized:
//			USER:				NAME
//			COMPUTER:		NAME
//			LOCATION: 		WHERE
//			EXPERIMENT:		NAME
// Latest change:			DATE
//######################################################################

//####[ Expt_Data ]#####################################################
//	Bart McGuyer, Department of Physics, Princeton University 2008
//
//	Expt_Data provides routines to simplify data-taking and interfacing with equipment.
//	A "DataTypes" panel is provided to select data to record during general 
// data-taking routines -- see "Explanation of Data Types convention" following the 
// table of contents below for more information.  
// Usually this file is costomized as needed for a particular experiment.  
// 
//	Acknowledgements:  
// -- This code comes from work performed while I was a graduate student 
//		in the research group of Professor William Happer at Princeton.  
//	-- This code builds on "Alex Procedures," a very useful set of Igor Pro
//		procedures written by Dr. Alex Johnson while working for Professor 
//		Charles Marcus at Harvard.  "Alex Procedures" is documented in Appendix 
//		D of its author's Ph.D. dissertation, and is available online at:
//			http://marcuslab.harvard.edu/how_to/alexprocedures.zip
//		However, this code is not compatible with "Alex Procedures." 
//	
//	Dependencies:  
//	-- Expt_Analysis for wave conventions and graphing...
#include ":Expt_Analysis"
//	-- getval, setval depend on user-defined functions in other procedure files.
//	-- This file uses conditional compiling (#if) to work on multiple computers, which requires IGOR Pro v6 or above.
//		For earlier versions of IGOR, just comment out the conditional compile statements.
//	
//	How to use these functions:
//	-- Use setval or getval at any time to change or read values ('idstr's or 'stream's)
//	-- Use the Data Types panel to select what variables (called 'stream's) you want to record (if any) during a sweep, and add a user comment (if desired)
//	-- Use a sweep routine, like do1d or do2d, to sweep a variable.  Graphs will be created for each entry setup in the Data Types panel.
//	
//	Customizing:
//	-- Make sure to update gains, offsets, etc... in getval() before you take data
//	-- Update setval, getval, needsACH, getlabel to match your equipment setup
//	-- To change the available data types in the DataTypes panel, update and run setupDataTypes()
//	-- Don't forget that you can create specialized versions of do1d, do2d, etc... as needed!
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com. 
//
// Possible Future Work:  
//	-- Maybe allow indefinite TIME, NOISE, DATE sweeps, by automatically resizing waves?  
// -- Consider making getval use an optional ACHnum parameter?  
// -- Find a better way to handle streams with duplicate idstr (e.g., ACH vs ACH2)? 
//	-- Improve doSch() - Maybe give the option to wait a duration for elapsed time with Sleep/A, instead of a fixed delay?
//	-- Make doFn(), to turn a NIDAQ DAC channel into a function generator (sine, triangle, square wave)?  
//	-- Maybe generalize DataTypes to allow arbitrary number of streams (limited to 4 for now)?  
//	-- Maybe use optional parameters (Igor manual pg IV-48) to allow function calls of do1d to be told a list of DataTypes to measure?  
// 
//	Notes:
//	-- idstr's are meant to be unique and not null strings (not "").  
//	-- WARNING: When choosing streams in the DataTypes panel, beware duplicates! 
//		Duplicate idstr will lead to wave name conflicts and overwritting.  
//		Make multiple idstr to prevent duplicates (e.g., 'ACH' and 'ACH2').
//	
//	####[ Table of Contents ]####
//	Menu Items:
//		"DataTypes Panel" added to the Macros menu.
//	Windows and Buttons:		Description:
//		showDataTypesPanel			This draws the Data Types panel, which selects the data streams for sweeping utilities to record
//		setdatatype						(PopupMenuControl) Sets the data type for a stream
//	Functions:							Description:
//	---- I/O and Axis Labels - set these up for your computer ----
//		*getval							Returns the current value of a data stream or idstr.  Used to capture data in sweeping utilities
//		*needsACH						Returns whether or not a data stream needs a NIDAQ ACH number (BNC-2090) during getval
//		*setval							Generic routine to set physical parameters
//		getData							Returns the current value for a stream, shorthand version.  
//		getlabel							returns text for an axis label for a given idstr, mostly used for new waves
//		updateAxisLabels				replaces axis labels in wavenote with current values in getlabel, for correcting mistakes or adding labels to wavenote if they didn't exist
//	---- Generalized Routines ----
//		do1d								Generalized 1D sweep - figures out from idstr what to sweep
//		sweep1d							Sweep like do1d without taking data or creating waves
//		do1davg							do1d that averages the measurement avg times
//		do2d								Generalized 2D sweep - figures out from idstr what to sweep
//		do2dsoft							do2d but ramps back fast sweep variable between loops
//		doSch								Generalized Scheduler - repeats a command following a given schedule of delays and executions
//	---- For the DataTypes variables ----
//		setupDataTypes					Sets up all necessary variables for the Data Types panel.  
//		getDT_DataTypes				returns the stringlist of available data types for the DataTypes panel
//		getDT_Stream					returns the data type (idstr) for a stream
//		setDT_Stream					sets the data type (idstr) for a stream
//		getDT_AchNum					returns the achnum for a stream
//		setDT_AchNum					sets the achnum for a stream
//		getDT_Flag						return whether or not a stream is in use (tests whether type == "-")
//		setDT_Comment		  			Sets the user comment of the DataTypes panel
//		getDT_Comment					Returns the user comment of the DataTypes panel
//	Static Functions:				Description:
//		endsweep							Use at end of sweep routines to print message to history and auto-save experiment
//		setupWaves1D					Prepares waves for do1d style sweeping routines.
//		setupWaves2D					Prepares waves for do2d style sweeping routines.
//		DT_ErrorCheckNum:  			Checks if num is a valid stream number (0 = yes)
//
//	*NOTE: These functions are conditionally compiled (for IGOR v6+, otherwise won't work).

//######################################################################
//	== Explanation of DataTypes Convention ==
//	
//	The DataTypes Panel is used to set what data is to be recorded during a data taking routing (ex: do1d).
//	There are 4 'streams' (indexed 1-4), and each can be set to a particular 'idstr' or data type.  
//	When needed, an ACH number can be selected for streams that use NIDAQ.  
//	If a stream is not in use, it is set to "-".  
//	A user comment can be entered into the panel, which will be added to the wavenote(s) of new data wave(s).  
//	Right now, only up to 4 active streams are supported.  
//	Streams with identical types should be avoided, as they will lead to duplicate waves in sweeping routines.  
//	To fix, create more idstr's (ex: ACH and ACH2 or LA1x and LA1y).
//	You must run setupDataTypes before trying to use the Data Types panel.
//######################################################################

//######################################################################
// Static Variables				(allow easy dynamic changes of code, but ONLY work for functions - not Macros!)
Static strconstant ksDTpath = "root:System:DataTypes"	//data folder location for global variables needed in this file
Static strconstant ksDTpathParent = "root:System"		//Parent folder of data folder location


//setupDataTypes:  Sets up all necessary variables for the Data Types panel.  
//Run the first time you use the panel, or if you want to update the available entries in the panel.
Function setupDataTypes()
	// Change data folder
	String PreviousDataFolder = GetDataFolder(1)	//Save previous data folder
	NewDataFolder/O/S $ksDTpathParent			//Make sure parent folder exists
	NewDataFolder/O/S $ksDTpath					//Change to new data folder
	
	//Change this to update the available choices in the Data Types panel!
	string/G sDT_DataTypes = "-;" + "ACH;ACH2;LA1x;LA1y;LA2x;LA2y;"
	
	//Data stream variables set by the panel
	Make/O/T/N=4 DT_Stream = {"-","-","-","-"}	//under development
	Make/O/N=4 DT_AchNum = {0, 0, 0, 0}			//under development
	
	//Comment variable set by panel, for user to add comment to data's wavenote
	string/G sDT_Comment = ""	//new way
	
	SetDataFolder PreviousDataFolder			//Reset data folder to value before function call
End

//getData:  Returns the current value for a stream, shorthand version.  
//NOTES:  This isn't used in sweeping routines b/c it may be slightly slower since it accesses variables with functions...
Function getData(num)
	variable num	//which stream (1-4)
	If(getDT_Flag(num))
		return getval(getDT_Stream(num),getDT_AchNum(num))
	Else
		printError("getData()","Stream isn't in use!")
		return NaN
	Endif
End


//####[ DATA-TAKING COMPUTER ROUTINES ]#################################
//	Place any data-taking computer code here (or in external files).
//	This section is conditionally compiled to give compatibility with 
//	analysis computers (non-data-taking or Macs), since file is built-in. 
#if Exists("fNIDAQ_BoardReset")		//test if NIDAQmx Tools installed (fails if MAC or not a data-taking computer)

//getval:  Returns the current value of a data stream or idstr.  Used to capture data in sweeping utilities
function getval(stream, ach)
	string stream				//from datatypes panel, or idstr
	variable ach				//which NIDAQ ACH, if applicable
	
	//Conversion variables
	variable/D Gain, Lsens, Rinline, ZeroOffset, Vapp, Rbias
	
	strswitch(stream)
	//Data Types Panel:--------------------------------------------------
		case "LA1x":			//Lockin LA1 channel x (V rmx)
			Lsens = 20e-3		//lockin sensitivity in volts (rms)
			ZeroOffset = 0.0	//unit = volts
			//getX_SR830("LA1")	//GPIB version
			return (Lsens * (nidaqRead(ach) - ZeroOffset) / (10))//NIDAQ version
		case "LA1y":			//Lockin LA1 channel y (V rms)
			Lsens = 20e-3		//lockin sensitivity in volts (rms)
			ZeroOffset = 0.0	//unit = volts
			//getY_SR830("LA1")	//GPIB version
			return (Lsens * (nidaqRead(ach) - ZeroOffset) / (10))//NIDAQ version
		case "LA2x":			//Lockin LA2 channel x (V rms)
			Lsens = 100e-3		//lockin sensitivity in volts (rms)
			ZeroOffset = 0.0	//unit = volts
			return (Lsens * (nidaqRead(ach) - ZeroOffset) / (10))//NIDAQ version
		case "LA2y":			//Lockin LA2 channel y (V rms)
			Lsens = 100e-3		//lockin sensitivity in volts (rms)
			ZeroOffset = 0.0	//unit = volts
			return (Lsens * (nidaqRead(ach) - ZeroOffset) / (10))//NIDAQ version
	//SERIAL PORT:-------------------------------------------------------
//		case "Temp":			//Oven temperature process value (PV), (degrees C, resolution 0.1)
//			return getTemp()
	//GPIB:--------------------------------------------------------------
		case "LA1phase":		//Lockin LA1 phase (degrees, resolution 0.01)
			return getPhaseSR830("la1")
		case "LA2phase":		//Lockin LA2 phase (degrees, resolution 0.1)
			return getPhaseSR530("la2")
	//NIDAQmx:-----------------------------------------------------------
		case "ACH":				//NIDAQmx channel voltage
			return nidaqRead(ach)
		case "ACH2":			//NIDAQmx channel voltage (to avoid streams with duplicate idstr)
			return nidaqRead(ach)
	//Special:-----------------------------------------------------------
	//DEFAULT:-----------------------------------------------------------
		default: 				//In case doesn't match anything...
			printError("getval","couldn't resolve stream!")
			return NaN
	endswitch
end

//needsACH:  Returns whether or not a data stream needs a NIDAQ ACH number (BNC-2090) during getval
function needsACH(stream)
	string stream				//from datatypes panel
	
	strswitch(stream)
	//Data Input Panel?:-------------------------------------------------
		case "LA1x":			//Lockin LA1 channel x
			return 1
		case "LA1y":			//Lockin LA1 channel y
			return 1
		case "LA2x":			//Lockin LA2 channel x
			return 1
		case "LA2y":			//Lockin LA2 channel y
			return 1
	//NIDAQmx:-----------------------------------------------------------
		case "ACH":				//NIDAQmx channel voltage
			return 1
		case "ACH2":			//NIDAQmx channel voltage
			return 1
	//Special:-----------------------------------------------------------
	//DEFAULT:-----------------------------------------------------------
		default: 				//For everything else - assume doesn't need ACH number.
			return 0
	endswitch
end

//setval: Generic routine to set physical parameters
//NOTE: Be careful with abort features here (ex: limit some range of values), b/c can stop sweeps, etc...
function setval(idstr, value)
	string idstr				//stream to change
	variable value				//desired value (make sure error check either here or in function calls!)
	
	strswitch(idstr)
	//GENERIC:-----------------------------------------------------------
		case "time":			// Do nothing, sweeping time
			break
		case "noise":			// Do nothing, sweeping time (calling it noise)
			break
		case "date":			// Do nothing, sweeping time (calling it date)
			break
	//MANUAL: (prompts the user to change)-------------------------------
//Here's an example of a manual prompt:  
//			case "NDF":				// "neutral density filter" wheel used to change laser intensity
//			DoAlert 0, "Please change NDF to " + num2istr(value) + " degrees, then click OK."	//Tells user to rotate NDF to new value, then click OK.
//			break
	//SERIAL PORT:-------------------------------------------------------
//		case "temp":			//Oven temperature setpoint (SP), (degrees C, resolution 0.1)
//			setTemp(value)		//Don't forget that the oven takes a long time to equilibrate!  
//			break
	//GPIB:--------------------------------------------------------------
		case "la1phase":		//Lockin LA1 phase (degrees, resolution 0.01)
			setPhaseSR830("la1",value)
			break
		case "la2phase":		//Lockin LA2 phase (degrees, resolution 0.1)
			setPhaseSR530("la2",value)
			break
	//NIDAQmx:-----------------------------------------------------------
		case "DAC0":			//NIDAQmx DAC0 output
			nidaqSet(0,value)
			break
		case "DAC1":			//NIDAQmx DAC1 output
			nidaqSet(1,value)
			break
	//DEFAULT:------------------------------------------------------------
		default: 				//In case  doesn't match anything...
			printError("setval","couldn't resolve idstr!")
	endswitch
end

//######################################
//	Stubs for DATA-TAKING COMPUTER ROUTINES
#else 
function getval(stream, ach)//make fake data...
	string stream				
	variable ach
	return gnoise(1)//return garbage for testing...
end
function needsACH(stream)//do nothing...
	string stream
	return 0
end
function setval(idstr, value)//do nothing...
	string idstr
	variable value		
end
//######################################
//	END of DATA-TAKING COMPUTER ROUTINES
#endif			//end conditional compile
//######################################


//######################################################################
//	WARNING: getlabel is changed frequently, following setval/getval!  

//getlabel:	returns text for an axis label for a given idstr, mostly used for new waves
Function/S getlabel(idstr)
	string idstr			//see setval, getval, etc...
	
	strswitch(idstr)
	//GENERIC:---------------------------------------------------------
		case "time":		
			return "Time (\\usec)"
		case "noise":		
			return "Time (\\usec)"
		case "date":		
			return "Date (Igor \\u)"
	//MANUAL:----------------------------------------------------------
//		case "NDF":
//			return "NDF filter setting (\\u¡)"
	//Data Input Panel:------------------------------------------------
		case "LA1x":		//Lockin voltage (rms)
			return "Lockin LA1 X (\\uV)"
		case "LA1y":		//Lockin voltage (rms)
			return "Lockin LA1 Y (\\uV)"
		case "LA2x":		//Lockin voltage (rms)
			return "Lockin LA2 X (\\uV)"
		case "LA2y":		//Lockin voltage (rms)
			return "Lockin LA2 Y (\\uV)"
	//SERIAL PORT:----------------------------------------------------	
//		case "temp":		//Oven temperature (deg C)
//			return "Temp (\\uC)"
	//GPIB:-----------------------------------------------------------
		case "la1phase":	//Lockin LA1 phase (degrees, SR830 resolution 0.01)
			return "Phase of Lockin LA1 (\\u¡)"
		case "la2phase":	//Lockin LA2 phase (degrees, SR530 resolution 0.1)
			return "Phase of Lockin LA2 (\\u¡)"
	//NIDAQmx:--------------------------------------------------------
		case "DAC0":		//NIDAQmx DAC0 output (V)
			return "DAC0 (\\uV)"
		case "DAC1":		//NIDAQmx DAC1 output (V)
			return "DAC1 (\\uV)"
		case "ACH":			//NIDAQmx channel voltage
			return "ACH (\\uV)"
		case "ACH2":		//NIDAQmx channel voltage (to avoid clash with ACH)
			return "ACH2 (\\uV)"
	//Special:--------------------------------------------------------
	//DEFAULT:--------------------------------------------------------
		default:				//In case  doesn't match anything...
			printError("getlabel()", "Cannot resolve idstr!")
			return ""
	endswitch
end

//updateAxisLabels:  replaces axis labels in wavenote with current values in getlabel, for correcting mistakes or adding labels to wavenote if they didn't exist
Function updateAxisLabels(num)
	variable num	//waveid for waves to update
	
	string list = listnum(num)
	if(!itemsinlist(list,";"))			//If nothing found...
		printError("updateAxisLabels()","No waves to update.")
		return 0					//"nicer" alternative to abort
	endif
	
	string item, idstr, wavenote
	variable ii
	
	for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
		item = stringfromlist(ii, list, ";")
		
		wavenote = note($item)
		idstr = StringByKey("d", wavenote)
		wavenote = ReplaceStringByKey("dlabel", wavenote, getlabel(idstr))
		idstr = StringByKey("x", wavenote)
		wavenote = ReplaceStringByKey("xlabel", wavenote, getlabel(idstr))
		
		//These axes don't exist for every wave, so we first test if they exist (if key is missing, get null string returned for idstr)
		idstr = StringByKey("y", wavenote)
		if(!stringmatch(idstr, ""))
			wavenote = ReplaceStringByKey("ylabel", wavenote, getlabel(idstr))
		endif
		idstr = StringByKey("z", wavenote)
		if(!stringmatch(idstr, ""))
			wavenote = ReplaceStringByKey("zlabel", wavenote, getlabel(idstr))
		endif
		idstr = StringByKey("t", wavenote)
		if(!stringmatch(idstr, ""))
			wavenote = ReplaceStringByKey("tlabel", wavenote, getlabel(idstr))
		endif
		
		Note/K $item wavenote		//replace wavenote with updated version
		
		Print "-- Updated axis labels for " + item + "."
	endfor
End

//######################################################################
//  Sweeping Utilities

//sweep1d:  Sweep like do1d without taking data or creating waves
function sweep1d(idstr, start, stop, numdivs, delay)
	string idstr			//see setval for allowed idstr's
	variable start			//starting value
	variable stop			//stopping value
	variable numdivs		//number of points minus 1
	variable delay			//seconds of delay between points (minimum - not accurate!)
	
	variable numpts = numdivs + 1	//number of data points
	variable t1, secs, ii				//for timekeeping and loop
	
	// Sweep loop
	make/D/O/N=(numpts) gate; gate[] = start + p*(stop-start)/numdivs
	setval(idstr, gate[0])		// Set initial condition
	sleep/S 3*delay				// Wait to equilibrate before ramp (in case it was a big change)  
	t1 = ticks						// start timer for time and noise sweeps
	for(ii = 0; ii < numpts; ii += 1)
		setval(idstr,gate[ii])	// Change the physical variable...
		sleep/S delay				// Wait the time delay (approximate!)
		//doupdate					// Update graphs so you see what's happening
	endfor
	
	// "endramp" like endsweep:  				//Print report to history, don't auto-save since no data taken.
	//variable mins = (ticks - t1) / (60*60)	//approx duration of sweep in minutes
	//Printf "-- Ramp finished at %s, elapsed time %.3f minutes.\tUser comment: \"%s\"\r", time(), mins, getDT_Comment()
	KillWaves/Z gate//, gate1, gate2			//delete gate variables
end

//do1d:  Generalized 1D sweep - figures out from idstr what to sweep
function do1d(idstr, start, stop, numdivs, delay)
	string idstr			//what to sweep, see setval for allowed idstr's
	variable start			//starting value
	variable stop			//stopping value
	variable numdivs		//number of points minus 1
	variable delay			//seconds of delay between points (minimum - not accurate!)
	
	// Global Variables -- don't load, but acquire values (faster execution if saved to local variables)
	string stream1 = getDT_Stream(1)
	string stream2 = getDT_Stream(2)
	string stream3 = getDT_Stream(3)
	string stream4 = getDT_Stream(4)
	variable achnum1 = getDT_AchNum(1)
	variable achnum2 = getDT_AchNum(2)
	variable achnum3 = getDT_AchNum(3)
	variable achnum4 = getDT_AchNum(4)
	variable d1 = getDT_Flag(1)	//flags (0 or 1) for whether data streams 1-4 are in use
	variable d2 = getDT_Flag(2)
	variable d3 = getDT_Flag(3)
	variable d4 = getDT_Flag(4)
	
	variable numpts = numdivs + 1	//number of data points
	variable waveid = nextwave()		//get wave index number
	variable t1, secs, ii				//for timekeeping and loop
	
	//Setup Data Waves
	string cmd		//details of command creating data, for wavenote
	sprintf cmd, "do1d(%s,%d,%d,%d,%d)", idstr, start, stop, numdivs, delay
	string wlist = setupWaves1D(cmd, idstr, start, stop, numdivs, delay)
	if(d1)
		WAVE w1 = $StringByKey("1",wlist)
	endif
	if(d2)
		WAVE w2 = $StringByKey("2",wlist)
	endif
	if(d3)
		WAVE w3 = $StringByKey("3",wlist)
	endif
	if(d4)
		WAVE w4 = $StringByKey("4",wlist)
	endif
	
	//Abort if not taking data...
	//if((d1 != 1) && (d2 != 1) && (d3 != 1) && (d4 != 1))
	//	printError("do1d()","No inputs were selected!")
	//	return 0
	//endif
	
	//gpibGotoRemoteAll()		//Switch devices to remove mode, as needed
	
	// Data taking loop
	make/D/O/N=(numpts) gate; gate[] = start + p*(stop-start)/numdivs
	setval(idstr, gate[0])		// Set initial condition
	sleep/S 3*delay				// Wait to equilibrate before ramp (in case it was a big change)  
	variable startDate = datetime	// save initial datetime value, for DATE idstr
	t1 = ticks						// start timer for time and noise sweeps, and for calculating elapsed time
	for(ii = 0; ii < numpts; ii += 1)
		setval(idstr,gate[ii])	// Change the physical variable...
		sleep/S delay				// Wait the time delay (approximate!)
		
		if(d1)						// Get your data
			w1[ii] = getval(stream1,achnum1)
		endif
		if(d2)
			w2[ii] = getval(stream2,achnum2)
		endif
		if(d3)
			w3[ii] = getval(stream3,achnum3)
		endif
		if(d4)
			w4[ii] = getval(stream4,achnum4)
		endif
		
		// TIME and NOISE:  Fix scaling of time axis to be more accurate than delay, update real-time
		If(stringmatch(idstr, "time")||stringmatch(idstr, "noise"))
			secs = (ticks - t1)/(60 * ii)		//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (secs is approx!)
			if(d1)
				setscale/p x,0,secs,w1	//Start x-axis at 0,set per-point scaling to the average time between points (approx!)
			endif
			if(d2)
				setscale/p x,0,secs,w2	
			endif
			if(d3)
				setscale/p x,0,secs,w3	
			endif
			if(d4)
				setscale/p x,0,secs,w4	
			endif
		endif
		// DATE:  Fix scaling of time axis to be more accurate than delay, update real-time
		If(stringmatch(idstr, "date"))
			secs = (ticks - t1)/(60 * ii)		//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (secs is approx!)
			if(d1)
				setscale/p x,startDate,secs,"dat",w1	//set per-point scaling to the average time between points (approx!)
			endif
			if(d2)
				setscale/p x,startDate,secs,"dat",w2	
			endif
			if(d3)
				setscale/p x,startDate,secs,"dat",w3	
			endif
			if(d4)
				setscale/p x,startDate,secs,"dat",w4	
			endif
		endif
		
		doupdate						// Update graphs so you see what's happening
	endfor
	
	//gpibGotoLocalAll()		//Switch all devices back to local mode
	endsweep(t1)					//Print information to history, auto-save experiment
end

//do1davg:  do1d that averages the measurement avg times
function do1davg(idstr, start, stop, numdivs, delay, avg)
	string idstr			// see setval for allowed idstr's
	variable start			// starting value
	variable stop			// stopping value
	variable numdivs		// number of points minus 1
	variable delay		// seconds of delay between points (minimum - not accurate!)
	variable avg			//number of times to average a data point
	
	// Error check the averaging instructions
	if((avg <= 0)||(floor(avg) != avg))
		printError("do1davg()","Invalid avg = " + num2str(avg) + ", must be positive integer!")
		return 0
	endif
	
	// Global Variables -- don't load, but acquire values (faster execution if saved to local variables)
	string stream1 = getDT_Stream(1)
	string stream2 = getDT_Stream(2)
	string stream3 = getDT_Stream(3)
	string stream4 = getDT_Stream(4)
	variable achnum1 = getDT_AchNum(1)
	variable achnum2 = getDT_AchNum(2)
	variable achnum3 = getDT_AchNum(3)
	variable achnum4 = getDT_AchNum(4)
	variable d1 = getDT_Flag(1)	//flags (0 or 1) for whether data streams 1-4 are in use
	variable d2 = getDT_Flag(2)
	variable d3 = getDT_Flag(3)
	variable d4 = getDT_Flag(4)
	
	variable numpts = numdivs + 1	//number of data points
	variable waveid = nextwave()		//get wave index number
	variable t1, secs, ii				//for timekeeping and loop
	
	//Setup Data Waves
	string cmd		//details of command creating data, for wavenote
	sprintf cmd, "do1davg(%s,%d,%d,%d,%d,%d)", idstr, start, stop, numdivs, delay, avg
	string wlist = setupWaves1D(cmd, idstr, start, stop, numdivs, delay)
	if(d1)
		WAVE w1 = $StringByKey("1",wlist)
	endif
	if(d2)
		WAVE w2 = $StringByKey("2",wlist)
	endif
	if(d3)
		WAVE w3 = $StringByKey("3",wlist)
	endif
	if(d4)
		WAVE w4 = $StringByKey("4",wlist)
	endif
	
	//Abort if not taking data...
	//if((d1 != 1) && (d2 != 1) && (d3 != 1) && (d4 != 1))
	//	printError("do1davg()","No inputs were selected!")
	//	return 0
	//endif
	
	//gpibGotoRemoteAll()		//Switch devices to remove mode, as needed
	
	// Data taking loop
	variable/D dummy1, dummy2, dummy3, dummy4//averaging bins...
	variable jj
	make/D/O/N=(numpts) gate; gate[] = start + p*(stop-start)/numdivs
	setval(idstr, gate[0])		// Set initial condition
	sleep/S 3*delay				// Wait to equilibrate before ramp (in case it was a big change)  
	variable startDate = datetime	// save initial datetime value, for DATE idstr
	t1 = ticks						// start timer for time and noise sweeps
	for(ii = 0; ii < numpts; ii += 1)
		setval(idstr,gate[ii])	// Change the physical variable...
		//sleep/S delay			// Wait the time delay (approximate!)
		
		dummy1 = 0; dummy2 = 0; dummy3 = 0; dummy4 = 0;
		for(jj = 0; jj < avg; jj += 1)		// Get your data, repeat avg times.
				sleep/S delay		// Wait the time delay (approximate!)
				if(d1)
					dummy1 += getval(stream1,achnum1)
				endif
				if(d2)
					dummy2 += getval(stream2,achnum2)
				endif
				if(d3)
					dummy3 += getval(stream3,achnum3)
				endif
				if(d4)
					dummy4 += getval(stream4,achnum4)
				endif
		endfor
		
		if(d1)// Average Data, have to do it this way b/c initial values were NaN's
			w1[ii] = dummy1/avg
		endif
		if(d2)
			w2[ii] = dummy2/avg
		endif
		if(d3)
			w3[ii] = dummy3/avg
		endif
		if(d4)
			w4[ii] = dummy4/avg
		endif
		
		// TIME and NOISE:  Fix scaling of time axis to be more accurate than delay, update real-time
		If(stringmatch(idstr, "time")||stringmatch(idstr, "noise"))
			secs = (ticks - t1)/(60 * ii)		//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (secs is approx!)
			if(d1)
				setscale/p x,0,secs,w1	//Start x-axis at 0,set per-point scaling to the average time between points (approx!)
			endif
			if(d2)
				setscale/p x,0,secs,w2	
			endif
			if(d3)
				setscale/p x,0,secs,w3	
			endif
			if(d4)
				setscale/p x,0,secs,w4	
			endif
		endif
		// DATE:  Fix scaling of time axis to be more accurate than delay, update real-time
		If(stringmatch(idstr, "date"))
			secs = (ticks - t1)/(60 * ii)		//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (secs is approx!)
			if(d1)
				setscale/p x,startDate,secs,"dat",w1	//set per-point scaling to the average time between points (approx!)
			endif
			if(d2)
				setscale/p x,startDate,secs,"dat",w2	
			endif
			if(d3)
				setscale/p x,startDate,secs,"dat",w3	
			endif
			if(d4)
				setscale/p x,startDate,secs,"dat",w4	
			endif
		endif
		
		doupdate						// Update graphs so you see what's happening
	endfor
	
	//gpibGotoLocalAll()		//Switch all devices back to local mode
	endsweep(t1)					//Print information to history, auto-save experiment
end

//do2d:  Generalized 2D sweep - figures out from idstr what to sweep
function do2d(idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2)
	//Outer Loop variables (slower sweep - hold fixed for fast sweep) = y
	string idstr1			// see setval for allowed idstr's
	variable start1		// starting value
	variable stop1			// stopping value
	variable numdivs1		// number of points minus 1
	variable delay1		// seconds of delay between points (minimum - not accurate!)
	//Inner Loop variables (fast sweep) = x
	string idstr2			// see setval for allowed idstr's
	variable start2		// starting value
	variable stop2			// stopping value
	variable numdivs2		// number of points minus 1
	variable delay2		// seconds of delay between points (minimum - not accurate!)
	
	// Global Variables -- don't load, but acquire values (faster execution if saved to local variables)
	string stream1 = getDT_Stream(1)
	string stream2 = getDT_Stream(2)
	string stream3 = getDT_Stream(3)
	string stream4 = getDT_Stream(4)
	variable achnum1 = getDT_AchNum(1)
	variable achnum2 = getDT_AchNum(2)
	variable achnum3 = getDT_AchNum(3)
	variable achnum4 = getDT_AchNum(4)
	variable d1 = getDT_Flag(1)	//flags (0 or 1) for whether data streams 1-4 are in use
	variable d2 = getDT_Flag(2)
	variable d3 = getDT_Flag(3)
	variable d4 = getDT_Flag(4)
	
	variable numpts1 = numdivs1 + 1		//number of data points
	variable numpts2 = numdivs2 + 1		//number of data points
	variable waveid = nextwave()			//get wave index number
	variable t1, secs, ii, jj				//for timekeeping and loop
	
	//Setup Data Waves
	string cmd		//details of command creating data, for wavenote
	sprintf cmd, "do2d(%s,%d,%d,%d,%d,%s,%d,%d,%d,%d)", idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2
	string wlist = setupWaves2D(cmd, idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2)
	if(d1)
		WAVE w1 = $StringByKey("1",wlist)
	endif
	if(d2)
		WAVE w2 = $StringByKey("2",wlist)
	endif
	if(d3)
		WAVE w3 = $StringByKey("3",wlist)
	endif
	if(d4)
		WAVE w4 = $StringByKey("4",wlist)
	endif
	
	//Abort if not taking data...
	if((d1 != 1) && (d2 != 1) && (d3 != 1) && (d4 != 1))
		printError("do2d()","No inputs were selected!")
		return 0
	endif
	
	//gpibGotoRemoteAll()		//Switch devices to remove mode, as needed
	
	// Data taking loop
	make/D/O/N=(numpts1) gate1; gate1[] = start1 + p*(stop1-start1)/numdivs1
	make/D/O/N=(numpts2) gate2; gate2[] = start2 + p*(stop2-start2)/numdivs2
	setval(idstr1, gate1[0])	// Set initial condition for outer loop
	setval(idstr2, gate2[0])	// Set initial condition for inner loop
	sleep/S 3*delay1				// Wait to equilibrate before ramp (in case it was a big change) 
	t1 = ticks						// start timer for time and noise sweeps
	// Outer Loop
	for(ii = 0; ii < numpts1; ii += 1)
		setval(idstr1, gate1[ii])	// Change the physical variable...
		setval(idstr2, gate2[0])	//	reset inner loop
		sleep/S delay1					// Wait the time delay (approximate!)
		
		//Inner Loop
		for(jj = 0; jj < numpts2; jj += 1)
			setval(idstr2,gate2[jj])	// Change the physical variable...
			sleep/S delay2					// Wait the time delay (approximate!)
			
			if(d1)					// Get your data
				w1[jj][ii] = getval(stream1,achnum1)	//row=jj, col=ii?
			endif
			if(d2)
				w2[jj][ii] = getval(stream2,achnum2)
			endif
			if(d3)
				w3[jj][ii] = getval(stream3,achnum3)
			endif
			if(d4)
				w4[jj][ii] = getval(stream4,achnum4)
			endif
		endfor
		
		// TIME and NOISE and DATE:  
		// -- Doesn't really make sense to rescale any axis in do2d...
		// -- fast axis = x is swept multiple times, and can't have different scalings for each y-value...
		// -- slow axis = y is swept once, but time doesn't make much sense as a y-axis since each x-axis sweep adds a big time delay...
		// -- So, don't have any rescaling code here analogous to what's in do1d...
		
		doupdate					// Update graphs so you see what's happening
	endfor
	
	//gpibGotoLocalAll()	//Switch all devices back to local mode
	endsweep(t1)				//Print information to history, auto-save experiment
end

//do2dsoft:  do2d but ramps back fast sweep variable between loops
function do2dsoft(idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2)
	//Outer Loop variables (slower sweep - hold fixed for fast sweep) = y
	string idstr1			// see setval for allowed idstr's
	variable start1		// starting value
	variable stop1			// stopping value
	variable numdivs1		// number of points minus 1
	variable delay1		// seconds of delay between points (minimum - not accurate!)
	//Inner Loop variables (fast sweep) = x
	string idstr2			// see setval for allowed idstr's
	variable start2		// starting value
	variable stop2			// stopping value
	variable numdivs2		// number of points minus 1
	variable delay2		// seconds of delay between points (minimum - not accurate!)
	
	// Global Variables -- don't load, but acquire values (faster execution if saved to local variables)
	string stream1 = getDT_Stream(1)
	string stream2 = getDT_Stream(2)
	string stream3 = getDT_Stream(3)
	string stream4 = getDT_Stream(4)
	variable achnum1 = getDT_AchNum(1)
	variable achnum2 = getDT_AchNum(2)
	variable achnum3 = getDT_AchNum(3)
	variable achnum4 = getDT_AchNum(4)
	variable d1 = getDT_Flag(1)	//flags (0 or 1) for whether data streams 1-4 are in use
	variable d2 = getDT_Flag(2)
	variable d3 = getDT_Flag(3)
	variable d4 = getDT_Flag(4)
	
	variable numpts1 = numdivs1 + 1		//number of data points
	variable numpts2 = numdivs2 + 1		//number of data points
	variable waveid = nextwave()			//get wave index number
	variable t1, secs, ii, jj				//for timekeeping and loop
	
	//Setup Data Waves
	string cmd		//details of command creating data, for wavenote
	sprintf cmd, "do2dsoft(%s,%d,%d,%d,%d,%s,%d,%d,%d,%d)", idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2
	string wlist = setupWaves2D(cmd, idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2)
	if(d1)
		WAVE w1 = $StringByKey("1",wlist)
	endif
	if(d2)
		WAVE w2 = $StringByKey("2",wlist)
	endif
	if(d3)
		WAVE w3 = $StringByKey("3",wlist)
	endif
	if(d4)
		WAVE w4 = $StringByKey("4",wlist)
	endif
	
	//Abort if not taking data...
	if((d1 != 1) && (d2 != 1) && (d3 != 1) && (d4 != 1))
		printError("do2dsoft()","No inputs were selected!")
		return 0
	endif
	
	//gpibGotoRemoteAll()		//Switch devices to remove mode, as needed
	
	// Data taking loop
	make/D/O/N=(numpts1) gate1; gate1[] = start1 + p*(stop1-start1)/numdivs1
	make/D/O/N=(numpts2) gate2; gate2[] = start2 + p*(stop2-start2)/numdivs2
	setval(idstr1, gate1[0])	// Set initial condition for outer loop
	setval(idstr2, gate2[0])	// Set initial condition for inner loop
	sleep/S 3*delay1				// Wait to equilibrate before ramp (in case it was a big change) 
	t1 = ticks						// start timer for time and noise sweeps
	// Outer Loop
	for(ii = 0; ii < numpts1; ii += 1)
		setval(idstr1, gate1[ii])	// Change the physical variable...
		setval(idstr2, gate2[0])	//	reset inner loop
		sleep/S delay1					// Wait the time delay (approximate!)
		
		//Inner Loop
		for(jj = 0; jj < numpts2; jj += 1)
			setval(idstr2,gate2[jj])	// Change the physical variable...
			sleep/S delay2					// Wait the time delay (approximate!)
			
			if(d1)					// Get your data
				w1[jj][ii] = getval(stream1,achnum1)	//row=jj, col=ii?
			endif
			if(d2)
				w2[jj][ii] = getval(stream2,achnum2)
			endif
			if(d3)
				w3[jj][ii] = getval(stream3,achnum3)
			endif
			if(d4)
				w4[jj][ii] = getval(stream4,achnum4)
			endif
		endfor
		
		//"Soft" - ramp back inner loop to initial value
		for(jj = numpts2-1; jj >= 0; jj -= 1)
			setval(idstr2,gate2[jj])	// Change the physical variable...
			sleep/S delay2					// Wait the time delay (approximate!)
		endfor
		
		doupdate					// Update graphs so you see what's happening
	endfor
	
	//gpibGotoLocalAll()	//Switch all devices back to local mode
	endsweep(t1)				//Print information to history, auto-save experiment
end

//endsweep:  Use at end of sweep routines to print message to history and auto-save experiment
Static Function endsweep(t1)
	variable t1		//starting time in ticks of data sweep
	variable mins = (ticks - t1) / (60*60)	//approx duration of sweep in minutes
	
	string dummy = ""	//list of what was measured...
	If(getDT_Flag(1))
		dummy += getDT_Stream(1) + ", "
	Endif
	If(getDT_Flag(2))
		dummy += getDT_Stream(2) + ", "
	Endif
	If(getDT_Flag(3))
		dummy += getDT_Stream(3) + ", "
	Endif
	If(getDT_Flag(4))
		dummy += getDT_Stream(4) + ", "
	Endif
	
	//Print report to history
	If(!stringmatch(dummy, ""))
		Printf "-- Created wave(s) # %d, measured %sfinished at %s, elapsed time %.3f minutes.\tUser comment: \"%s\"\r", nextwave() - 1, dummy, time(), mins, getDT_Comment()
	Else	//If no data recorded...
		Printf "-- NO wave(s) created, finished at %s, elapsed time %.3f minutes.\tUser comment: \"%s\"\r", time(), mins, getDT_Comment()
	Endif	
	
	if(mins > 2)
		saveexperiment	//Save experiment after long sweeps, but not after short ones (saves time).  
		//WARNING:  This can take a lot of time for big files.
	endif
	
	KillWaves/Z gate, gate1, gate2		//delete gate variables
end

//setupWaves1D:  Prepares waves for do1d style sweeping routines.
Static Function/T setupWaves1D(cmd, idstr, start, stop, numdivs, delay)
	string cmd				//full text of command that is creating waves (ex: "do1d(...all values...)")
	string idstr			//what to sweep, see setval for allowed idstr's
	variable start			//starting value
	variable stop			//stopping value
	variable numdivs		//number of points minus 1
	variable delay			//seconds of delay between points (minimum - not accurate!)
	
	// DataTypes variables...
	string stream	//fill this later
	string comment = getDT_Comment()
	
	// local variables
	variable numpts = numdivs + 1	//number of data points
	variable waveid = nextwave()		//get wave index number
	string wname			//placeholder for name of wave to create
	string wavenote		//For wavenotes
	
	//Stringlist of "(stream #):(wavename);" containing waves created, to return
	string wlist=""
	
	sprintf wavenote, "waveid:%d;cmd:%s;date:%s;time:%s;", waveid, cmd, date(), time()
	wavenote += "comment:" + comment + ";"	//User comment from Data Types Panel
	wavenote += "x:" + idstr + ";" + "xlabel:" + getlabel(idstr) + ";"
	
	variable ii
	for(ii = 1; ii <= 4; ii += 1)//Loop over DataTypes streams (1-4)
		if(getDT_Flag(ii))
			//This data stream is active, so let's prepare a wave:
			
			//Get values from DataTypes variables
			stream = getDT_Stream(ii)
			
			sprintf wname, "%s%s_%d", stream, idstr, waveid	//Create name of new wave
			wlist += num2istr(ii) + ":" + wname + ";"			//add this wave name to the running string list
			Make/D/O/N=(numpts) $wname = NaN						//Create wave and local handle
			setscale/I x start, stop, "", $wname					//Scale x-axis
			
			//Add meta-data to the wavenote...
			Note/NOCR $wname wavenote + "d:" + stream + ";dlabel:" + getlabel(stream) + ";"
			
			showwaves(wname)		//Display a graph
			graphPosition(ii)		//position the graph
		else
			//This stream isn't active, so put a null wave name:
			wlist += num2istr(ii) + ":;"
		endif
	endfor
	
	return wlist
End

//setupWaves2D:  Prepares waves for do2d style sweeping routines.
Static Function/T setupWaves2D(cmd, idstr1, start1, stop1, numdivs1, delay1, idstr2, start2, stop2, numdivs2, delay2)
	string cmd				//full text of command that is creating waves (ex: "do2d(...all values...)")
	//Outer Loop variables (slower sweep - hold fixed for fast sweep) = y
	string idstr1			// see setval for allowed idstr's
	variable start1		// starting value
	variable stop1			// stopping value
	variable numdivs1		// number of points minus 1
	variable delay1		// seconds of delay between points (minimum - not accurate!)
	//Inner Loop variables (fast sweep) = x
	string idstr2			// see setval for allowed idstr's
	variable start2		// starting value
	variable stop2			// stopping value
	variable numdivs2		// number of points minus 1
	variable delay2		// seconds of delay between points (minimum - not accurate!)
	
	// DataTypes variables...
	string stream			//fill this later
	string comment = getDT_Comment()
	
	// local variables
	variable numpts1 = numdivs1 + 1		//number of data points
	variable numpts2 = numdivs2 + 1		//number of data points
	variable waveid = nextwave()			//get wave index number
	string wname			//placeholder for name of wave to create
	string wavenote		//For wavenotes
	
	//Stringlist of "(stream #):(wavename);" containing waves created, to return
	string wlist=""
	
	sprintf wavenote, "waveid:%d;cmd:%s;date:%s;time:%s;", waveid, cmd, date(), time()
	wavenote += "comment:" + comment + ";"	//User comment from Data Types Panel
	wavenote += "y:" + idstr1 + ";" + "ylabel:" + getlabel(idstr1) + ";"
	wavenote += "x:" + idstr2 + ";" + "xlabel:" + getlabel(idstr2) + ";"
	
	variable ii
	for(ii = 1; ii <= 4; ii += 1)//Loop over DataTypes streams (1-4)
		if(getDT_Flag(ii))
			//This data stream is active, so let's prepare a wave:
			
			//Get values from DataTypes variables
			stream = getDT_Stream(ii)
			
			sprintf wname, "%s%s%s_%d", stream, idstr2, idstr1, waveid	//Create name of new wave
			wlist += num2istr(ii) + ":" + wname + ";"			//add this wave name to the running string list
			Make/D/O/N=((numpts2),(numpts1)) $wname = NaN;	//Create wave and local handle
			setscale/I y start1, stop1, "", $wname				//Scale x-axis
			setscale/I x start2, stop2, "", $wname				//Scale x-axis
			
			//Add meta-data to the wavenote...
			Note/NOCR $wname wavenote + "d:" + stream + ";dlabel:" + getlabel(stream) + ";"
			
			showwaves(wname)		//Display a graph
			graphPosition(ii)		//position the graph
		else
			//This stream isn't active, so put a null wave name:
			wlist += num2istr(ii) + ":;"
		endif
	endfor
	
	return wlist
End

//doSch:  Generalized Scheduler - repeats a command following a given schedule of delays and executions
//NOTE: Timing is estimated!  Auto-saves during doSch can significantly change time delay between executions.
//Also, I recommend making cmd log important information (waves, times, values...) in a computer-processable
//format in a Notebook.  This really helps with analysis of scheduled experiments.  
//Note:  doesn't allow parenthesis in cmd?
function doSch(sch, cmd)
	string sch			// schedule, example: "0:1;"
	//NOTE: sch Formatting Convention:
	//  sch must be a string list with elements (or "sequence") "a:b;" where a = delay time (minutes) and b = numer of repetitions.
	//  For example:  sch = "0:1;5:2;10:3;20:inf;"
	//  This executes one time without delay, then waits 5 minutes and executes, then waits another 5 minutes and executes, 
	//  then executes after a 10 minute wait three times, then starts an infinite loop of measurements after 20 minutes each.
	//  NOTE: the number of repetitions must be >= 0 or == inf and the delay must >= 0 minutes.
	string cmd			// command to execute
	//NOTE: cmd can reference internal timing results from doSch:
	//  For example:  cmd = "print mins, prevdelay, nextdelay, rep"
	//  This would print the elapsed time, the length of the previous delay, the length of the next delay (all in minutes), and the current rep # (starting with 1).
	//  NaN is given for prevdelay and nextdelay if there is no prior or next rep, respectively.  
	//  Could easily add more variables in the future, such as the current repetition or element number.
	
	// Analyze sch and Do Error Checking... Last chance to prevent loop from starting!  
	if(stringmatch(cmd,""))					//Do we have a valid command?
		printError("doSch()","Empty command!")
		return 0//soft abort
	endif
	variable NumElem = ItemsInList(sch)	//How many blocks of "delay:repetitions;" are there?
	variable ii							//dummy variable to loop over these elements
	string Elem							//current element to work with
	variable delay, numrep			//contents of current Elem (units are minutes and number, respectively)
	variable estTime = 0			//estimated total time for sch.
	variable totNum = 0				//total number of executions for sch.
	for(ii = 0; ii < NumElem; ii += 1)		//Loop over the elements for inspection...
		Elem = StringFromList(ii,sch)			
		if(ItemsInList(Elem,":") != 2)		//If the formatting of Elem is not "x:y", ie: incorrect number of ":".
			printError("doSch()","Invalid formatting of scheduling string!")
			return 0//soft abort
		endif
		
		delay = str2num(StringFromList(0,Elem,":"))
		numrep = str2num(StringFromList(1,Elem,":"))
		if((numtype(delay) != 0) || (numtype(numrep) == 2) || (delay < 0) || ((numrep != inf) && (numrep < 0)) || (numrep != round(numrep)))
			printError("doSch()","Invalid schedule!  Delays must be >= 0 and Repetitions an integer >= 0 or == inf.")
			return 0//soft abort
		endif
		
		//If this Elem is an infinite loop, is there anything scheduled after it?
		if((numrep == inf) && (ii != NumElem - 1))
			printError("doSch()","Invalid schedule!  Infinite loop before last element.")
			return 0//soft abort
		endif
		
		//Estimated timing information:
		if(numrep == 0)	//is this a delay without measurement?
			estTime += delay
		else
			estTime += numrep*delay
		endif
		totNum += numrep	//add repetitions to total
	endfor
	
	//POINT OF NO RETURN before executing the schedule is RIGHT HERE.
	
	// Edit datatypes comment -- put flag at beginning to denote data was taken during doSch().
	string DTcomment = getDT_Comment()
	setDT_Comment("[doSch] " + DTcomment)
	
	// Print overview to history (safety measure b/c Igor doesn't always print function call to history correctly for aborted functions...)
	Print "################################"
	Print "[doSch] -- Starting scheduled routine..."
	if(numrep == inf)	//test if this is an infinite loop -- uses leftover value in numrep from error checking...
		Print "< ! > WARNING!  Your schedule is an INFINITE loop!  YOU MUST ABORT to stop execution."
	else
		Printf "-- Estimated total (delay) time of %.2f minutes (%.2f hours) with %.0f executions of '%s'.\r", estTime, estTime/60, totNum, cmd
	endif
	Print "-- ABORT at any time by pressing Ctrl-Break (Command-Period on MAC)."
	
	// Scheduled Loop:
	variable t1, mins = 0		//for timekeeping
	variable jj						//dummy looping variable for repetitions (ii is for Elem)
	variable globalRep = 0		//Keep index of total number of executions...
	variable nextdelay			//upcoming delay time in minutes, to be passed to cmd if needed
	string exec						//placeholder for cmd to execute after modification (if needed)
	Print "-- T = 0.00 is NOW:  \t" + time() + " " + date()
	Print "################################"
	t1 = ticks						// start timer!  This is time==0 right here.
	for(ii = 0; ii < NumElem; ii += 1)	//LOOP over Elem in sch
		//Get info from sch
		Elem = StringFromList(ii,sch)	
		delay = str2num(StringFromList(0,Elem,":"))
		numrep = str2num(StringFromList(1,Elem,":"))
		nextdelay = delay
		
		//update timing
		mins = (ticks - t1)/(60 * 60)	//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (mins is approx!)
		
		//Inform user where you are in the schedule!
		if(numrep == inf)			//Is this an infinite loop?
			Printf "[doSch] -- Starting INFINITE loop with delays of %.2f minutes.  ", delay
//		elseif(numrep==0)			//Is this a delay without execution?
//			Printf "[doSch] -- STARTING element # %.0f / %.0f:  1 x %.2f mins, NO execution(s).  ", ii+1, numElem, delay
		else							//default case
			Printf "[doSch] -- STARTING element # %.0f / %.0f:  %.0f x %.2f mins.  ", ii+1, numElem, numrep, delay
		endif
		Printf "T = %.2f minutes (%.2f hours) at %s on %s.\r", mins, mins/60, time(), date()
		
		for(jj = 0; jj < numrep; jj += 1)	//LOOP over repetitions (infinite loop if numrep = inf, skips if numrep = 0)
			globalRep += 1			//Keep index of total number of executions...
			
			//Set nextdelay
			if(jj == numrep-1)	// if this is the last rep in this Elem, fill nextdelay with the delay of the next Elem.
				nextdelay = str2num(StringFromList(0,StringFromList(ii + 1,sch),":"))
				//NOTE:  if there is no next or previous Elem, then this gives NaN.  Also, this is compatible with numrep = 0 b/c no execution.
			endif
			
			//Inform user...
			if(numrep==inf)
				Print "< ! > WARNING!  Infinite Loop! ABORT with Ctrl-Break (Command-Period on MAC)."
			endif
			Printf "[doSch] -- REP # %.0f / %.0f (rep # %.0f / %.0f total):  Waiting %.2f mins...  ", jj+1, numrep, globalRep, totNum, delay
			
			Sleep/S 60*delay		//wait "delay" minutes.  Maybe use try-catch-endtry here to deal with accidental aborts?
			
			//Prepare and execute cmd:
			// "mins" -> mins, "rep" -> current rep#, "prevdelay" -> delay, "nextdelay" -> nextdelay	(could add more in the future)
			exec = cmd				//reload for editing...
			exec = ReplaceString("prevdelay", exec, num2str(delay))		//length of delay before this execution in minutes
			exec = ReplaceString("nextdelay", exec, num2str(nextdelay))	//length of delay after this execution in minutes
			mins = (ticks - t1)/(60 * 60)	//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (mins is approx!)
			exec = ReplaceString("rep", exec, num2str(globalRep))			//global rep number
			exec = ReplaceString("mins", exec, num2str(mins))				//elapsed time in minutes
			Printf "Executing at T = %.2f minutes (%.2f hours)...\r", mins, mins/60
			Execute/Q exec; 		//AbortOnRTE	//Execure command. Optional: Abort if there is a run-time error!
			
			if((delay>5) && (numrep>0))	// auto-save experiment if delay > 5 min and there was at least one execution
				saveexperiment		//WARNING: this can significantly add to delay between repetitions...
			endif
		endfor
		
		if(numrep == 0)			//DELAY ONLY if numrep = 0
			globalRep += 1			//Keep index of total number of executions...
			
			Printf "[doSch] -- REP # %.0f / %.0f (rep # %.0f / %.0f total):  Waiting %.2f mins...  NO execution.\r", jj+1, numrep, globalRep, totNum, delay
			
			Sleep/S 60*delay		//wait "delay" minutes.  Maybe use try-catch-endtry here to deal with accidental aborts?
		endif
		
		//doupdate					// Update graphs so you see what's happening
		saveexperiment				// auto-save experiment - can significantly add to delay between elements!
	endfor
	
	//NOTE:  The following code only executes if the user doesn't setup an infinite schedule or abort:
	
	setDT_Comment(DTcomment)	// Reset datatypes comment to original content.  Note that this isn't perfect, as cmd may change it.
	saveexperiment					// auto-save experiment for safety
	
	// Print final info to history
	mins = (ticks - t1)/(60 * 60)	//60.15 tics/sec on Mac, 60 for PC --> limits timing resolution ~ 15ms.  (mins is approx!)
	Print "################################"
	Print "[doSch] -- Finished scheduled routine!"
	Printf "-- Total duration was %.2f minutes (%.2f hours).\r", mins, mins/60
	Print "-- Done at " + time() + " on " + date() + "."
	Print "################################\r\r"
end

//######################################################################
//  Data Type Panel and related functions

//Add datatypes to the Macros menu
Menu "Macros"
	"DataTypes Panel", showDataTypesPanel()
End

//showDataTypesPanel:  This draws the Data Types panel, which selects the data streams for sweeping utilities to record
//NOTE:  This was adapted from the old Window Macro datatypespanel() into a function, since Macro's have all sorts of troubles.
Function showDataTypesPanel() : Panel //not sure adding ": Panel" here does anything...
	PauseUpdate; Silent 1		// building window...
	NewPanel/N=DataTypes/W=(500,500,500+180,500+150)	//left, top, right, bottom (sized ok for Windows XP)
	
	// Text across top
	DrawText 15,15,"Input Type"
	DrawText 100,15,"NIDAQ"
	
	//	Global Variables (b/c panel alters them)
	WAVE DT_AchNum = $(ksDTpath + ":DT_AchNum")//note, index = stream # - 1.
	SVAR sDT_Comment = $(ksDTpath + ":sDT_Comment")
	//DT_DataTypes is accessed by getDT_DataTypes()
	//popvalue for streams is set by getDT_Stream() to get current data type
	
	//Data Stream Inputs 1-4
	PopupMenu datatype1, pos={15,15}, size={70,21}, proc=setDataType, title="1"
	PopupMenu datatype1, mode=1, bodyWidth= 70, popvalue=getDT_Stream(1), value=getDT_DataTypes()
	PopupMenu datatype2, pos={15,40}, size={70,21}, proc=setDataType, title="2"
	PopupMenu datatype2, mode=1, bodyWidth= 70, popvalue=getDT_Stream(2), value=getDT_DataTypes()
	PopupMenu datatype3, pos={15,65}, size={70,21}, proc=setDataType,title="3"
	PopupMenu datatype3, mode=1, bodyWidth= 70, popvalue=getDT_Stream(3), value=getDT_DataTypes()
	PopupMenu datatype4, pos={15,90}, size={70,21}, proc=setDataType,title="4"
	PopupMenu datatype4, mode=1, bodyWidth= 70, popvalue=getDT_Stream(4), value=getDT_DataTypes()
	//NIDAQ Channel numbers (range 0-15, show/hide as needed - toggled by setDataType())
	SetVariable setach1,pos={100,17},size={70,15},disable=1,title="ACH"
	SetVariable setach1,limits={0,15,1},value=DT_AchNum[0]
	SetVariable setach2,pos={100,42},size={70,15},disable=1,title="ACH"
	SetVariable setach2,limits={0,15,1},value=DT_AchNum[1]
	SetVariable setach3,pos={100,67},size={70,15},disable=1,title="ACH"
	SetVariable setach3,limits={0,15,1},value=DT_AchNum[2]
	SetVariable setach4,pos={100,92},size={70,15},disable=1,title="ACH"
	SetVariable setach4,limits={0,15,1},value=DT_AchNum[3]
	
	//  User comment input
	DrawText 5,130,"Comment"
	SetVariable comment,pos={5,130},size={170,16},title = " ",value=sDT_Comment
End

//setDataType:  (PopupMenuControl) Sets the data type for a stream
Function setDataType (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName	//control name
	Variable popNum	//which item is currently selected (1-based)
	String popStr		//contents of current popup item as string
	
	string num = ctrlName[8]//gets # from "datatype#".  Only captures single character...
	setDT_Stream(str2num(num), popStr)//set the new stream type
	
	//Toggle hide/show nidaq ACH SetVariable as needed:
	setvariable $("setach" + num), disable=!needsACH(popStr)
End

//getDT_DataTypes:  returns the list of available data types for the DataTypes panel
Function/S getDT_DataTypes()
	SVAR sDT_DataTypes = $(ksDTpath + ":sDT_DataTypes")
	return sDT_DataTypes
end

//getDT_Stream:  returns the data type (idstr) for a stream
Function/S getDT_Stream(num)
	variable num	//which stream
	
	if(DT_ErrorCheckNum(num))//error catch for num...
		printError("getDT_Stream","invalid stream selection!")
		return "-"	//soft abort
	endif
	
	WAVE/T DT_Stream = $(ksDTpath + ":DT_Stream")
	return DT_Stream[num-1]
End

//setDT_Stream:  returns the data type (idstr) for a stream
Function setDT_Stream(num, type)
	variable num	//which stream
	string type		//new type for this stream
	
	if(DT_ErrorCheckNum(num))	//error catch for num...
		printError("setDT_Stream","invalid stream selection!")
		return 0	//soft abort
	endif
	
	if(FindListItem(type,getDT_DataTypes())==-1)
		printError("setDT_Stream","invalid data type suggestion!")
		return 0	//soft abort
	endif
	
	WAVE/T DT_Stream = $(ksDTpath + ":DT_Stream")
	DT_Stream[num-1] = type
End

//getDT_AchNum:  returns the achnum for a stream
Function getDT_AchNum(num)
	variable num	//which stream
	
	if(DT_ErrorCheckNum(num))	//error catch for num...
		printError("getDT_ACHnum","invalid stream selection!")
		return -1	//soft abort
	endif
	
	WAVE DT_AchNum = $(ksDTpath + ":DT_AchNum")
	return DT_AchNum[num-1]
End

//setDT_AchNum:  sets the achnum for a stream
Function setDT_AchNum(num, ach)
	variable num	//which stream
	variable ach	//new ach channel number
	
	if(DT_ErrorCheckNum(num))	//error catch for num...
		printError("setDT_ACHnum","invalid stream selection!")
		return -1	//soft abort
	endif
	
	//don't have an error check for AchNum...  
	
	WAVE DT_AchNum = $(ksDTpath + ":DT_AchNum")
	DT_AchNum[num-1] = ach
End

//getDT_Flag:  return whether or not a stream is in use (tests whether type == "-")
Function getDT_Flag(num)
	variable num	//which stream
	//let getDT_STream do the error catch for num...
	return !stringmatch(getDT_Stream(num),"-")
End

//setDT_Comment:  Sets the user comment of the DataTypes panel
Function setDT_Comment(cmt)
	string cmt	//desired comment
	SVAR sComment = $(ksDTpath + ":sDT_Comment")
	sComment = cmt
End

//getDT_Comment:  Returns the user comment of the DataTypes panel
Function/S getDT_Comment()
	SVAR sComment = $(ksDTpath + ":sDT_Comment")
	return sComment
End

//DT_ErrorCheckNum:  Checks if num is a valid stream number (0 = yes)
Static Function DT_ErrorCheckNum(num)
	variable num	//stream number to test
	if((floor(num)==num)&&(num>=1)&&(num<=4))
		return 0//yes, ok stream
	else
		return 1//invalid b/c out of range or non-integer
	endif
End

