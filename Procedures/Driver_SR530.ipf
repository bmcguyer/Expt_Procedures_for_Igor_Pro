#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0	// This File's Version

//####[ Driver_SR530 ]##################################################
//	Bart McGuyer, Department of Physics, Princeton University 2008
//	Procedure file to work with a Stanford Research Systems SR530 Lockin amplifier.
//	Acknowledgements:  
// -- This code comes from work performed while I was a graduate student 
//		in the research group of Professor William Happer.  
// 
//	NOTE:  SR530 from before ~ 1991 have to be modified for modern GPIB 
// (contact SRS with the serial number to check). To modify, 
//	they'll tell you to solder ~ 270 pF from pins10-17 on chip # 75161.  
//	I did this to one lockin, and it worked for me. 
// Even after modification, old lockins still uses very old commands and will not respond 
//	to *IDN? or ID?.  Otherwise, they still work well in a gpib chain with more modern devices.
//	
//	Dependencies:  
//	-- DAQ_GPIB procedure file commands:  gpibQuery(name, message), gpibSend(name, message)
//#include ":DAQ_GPIB"
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com.
//	-- v2.0: 9/21/2009 - Cleaned up code a bit.
//
//	Notes:  
//	-- Old SR530 freaks out and resets if you send it an individual device clear message!  
//	-- Speed of GPIB readings:
//		Measured the speed of getX... to be < 6.5 ms (vs. SR830 < 20ms)!!!!  That's as fast as NIDAQ!?!
//		Speed testing code: t1 = startmstimer;getX_SR530("LA2");Print (stopmstimer(t1)*1e-6)
//	-- getX and getY return values, but they seem to have nothing to do with the actual reading (noise?)!!!!
//	
//	####[ Table of Contents ]####
//	Functions:						Description:
//		setPhaseSR530					Sets lockin phase in degrees
//		getPhaseSR530					Returns lockin phase in degrees
//	removed b/c unreliable:	getX_SR530		Returns X output in volts (signal, don't need to scale)
//	removed b/c unreliable:	getY_SR530		Returns Y output in volts (signal, don't need to scale)
//		getScaleSR530			  		Returns lockin sensitivity in volts



//setPhaseSR530:  Sets lokin phase setting in degrees
Function setPhaseSR530(devname, phase)
	string devname				//name for DAQ_GPIB call
	variable phase			//Desired phase in degrees.  Note:  Max precision is 1/10 of a degree.
	gpibSend(devname, "P " + num2str(phase))
End

//getPhaseSR530:  Returns lockin phase setting in degrees
Function getPhaseSR530(devname)
	string devname				//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "P"))
End

//NOTE: Unreliable!  Output is wrong!
//getX_SR530:  Returns x output in volts (signal, don't need to scale)
//Function getX_SR530(devname)
//	string devname				//name for DAQ_GPIB call
//	return str2num(gpibQuery(devname, "QX"))
//End

//NOTE: Unreliable!  Output is wrong!
//getY_SR530:  Returns x output in volts (signal, don't need to scale)
//Function getY_SR530(devname)
//	string devname				//name for DAQ_GPIB call
//	return str2num(gpibQuery(devname, "QY"))
//End

//getScaleSR530:  Returns lockin sensitivity in volts
Function getScaleSR530(devname)
	string devname
	
	variable n = str2num(gpibQuery(devname, "G"))
	switch(n)
		case 1:
			return 10e-9
		case 2:
			return 20e-9
		case 3:
			return 50e-9
		case 4:
			return 100e-9
		case 5:
			return 200e-9
		case 6:
			return 500e-9
		case 7:
			return 1e-6
		case 8:
			return 2e-6
		case 9:
			return 5e-6
		case 10:
			return 10e-6
		case 11:
			return 20e-6
		case 12:
			return 50e-6
		case 13:
			return 100e-6
		case 14:
			return 200e-6
		case 15:
			return 500e-6
		case 16:
			return 1e-3
		case 17:
			return 2e-3
		case 18:
			return 5e-3
		case 19:
			return 10e-3
		case 20:
			return 20e-3
		case 21:
			return 50e-3
		case 22:
			return 100e-3
		case 23:
			return 200e-3
		case 24:
			return 500e-3
		default:			//Error catch
			return NaN
	endswitch
End

