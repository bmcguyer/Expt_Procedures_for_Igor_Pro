#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0	// This File's Version

//####[ Driver_SR830 ]##################################################
//	Bart McGuyer, Department of Physics, Princeton University 2008
//	Procedure file to work with Stanford Research Systems SR830 Lockin amplifier.
//	Acknowledgements:  
// -- This code comes from work performed while I was a graduate student 
//		in the research group of Professor William Happer.  
//	
//	Dependencies:  
//	-- DAQ_GPIB procedure file commands:  gpibQuery(name, message), gpibSend(name, message)
//#include ":DAQ_GPIB"
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com.
//	-- v2.0: 9/21/2009 - Cleaned up code.
//
//	Notes:
//	-- Speed of GPIB readings:
//		Measured the speed of getX... to be < 20 ms!!!!  That's as fast as NIDAQ!?!
//		Speed testing code: t1 = startmstimer;getX_SR830("LA1");Print (stopmstimer(t1)*1e-6)
//	
//	####[ Table of Contents ]####
//	Functions:						Description:
//		setPhaseSR830					Sets lockin phase in degrees
//		getPhaseSR830					Returns lockin phase in degrees
//		getX_SR830			 			Returns X output in volts (signal, don't need to scale)
//		getY_SR830			  			Returns Y output in volts (signal, don't need to scale)
//		getR_SR830			  			Returns R output in volts (signal, don't need to scale)
//		getTheta_SR830			  		Returns Theta output in degrees


//setPhaseSR830:  Sets lokin phase setting in degrees
Function setPhaseSR830(devname, phase)
	string devname			//name for DAQ_GPIB call
	variable phase			//Desired phase in degrees.  Note:  Max precision is 1/100 of a degree.
	gpibSend(devname, "PHAS " + num2str(phase))
End

//getPhaseSR830:  Returns lockin phase setting in degrees
Function getPhaseSR830(devname)
	string devname			//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "PHAS?"))
End

//getX_SR830:  Returns X output in volts (signal, don't need to scale)
Function getX_SR830(devname)
	string devname			//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "OUTP? 1"))
End

//getY_SR830:  Returns Y output in volts (signal, don't need to scale)
Function getY_SR830(devname)
	string devname			//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "OUTP? 2"))
End

//getR_SR830:  Returns R output in volts (signal, don't need to scale)
Function getR_SR830(devname)
	string devname			//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "OUTP? 3"))
End

//getTheta_SR830:  Returns Theta output in degrees
Function getTheta_SR830(devname)
	string devname			//name for DAQ_GPIB call
	return str2num(gpibQuery(devname, "OUTP? 4"))
End