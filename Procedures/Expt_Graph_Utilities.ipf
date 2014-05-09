#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0		// This File's Version

//####[ Graph_Utilities ]###############################################
//	Bart McGuyer, Department of Physics, Princeton University 2008 
//	Provides routines to look at parts of imageplot waves or remove baseline in 1d waves.
//	Acknowledgements:  
// -- This code comes from work performed while I was a graduate student 
//		in the research group of Professor William Happer.  
// -- The 2D profile utility is based off a similar utility from 
// 	"Alex Procedures", a set of Igor codes that is freely available 
//		online at the research group website of Professor Charles Marcus at Harvard:   
//			http://marcuslab.harvard.edu/how_to/alexprocedures.zip
//	
//	Assumptions:
//	-- Igor Pro v5 and above 
//	-- This code is meant to be stand-alone, and doesn't depend on Expt_Analysis or Expt_Data.  
//	
//	Possible Future Work:
//	-- These utilities can be greatly improved... 
//		For example: undo buttons, pulldowns for source waves, interference of buttons with annotations, trouble when opened on many windows at once,...
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com.
//	
//	####[ Table of Contents ]####
//	Menu Items:
//		"2D-Graph Profile Utility" and "1D-Graph Baseline Tool" added to the Macros menu.
//	Functions:							Description:
//		graphProfileUtility				Tool to show and save horizontal or vertical profiles through a 2d graph, say for an array of microwave scans
//		graphBlTool							Tool to remove baseline in 1d plots, say for normalizing raw spectroscopy data into contrast
//	Static Functions:				Description:
//		graphProfileButton				button function for graphProfileUtility
//		graphBlToolbutton					button function for graphBlToolbutton

//######################################################################
#include <Readback ModifyStr>		//Needed to parse TraceInfo data
#include <Axis Utilities>				//Need this to copy axes label text
//#include <Graph Utility Procs>



//######################################################################
//	Menu Items:  
//Add utilities to the Macros menu
Menu "Macros"
	"2D-Graph Profile Utility", graphProfileUtility()
	"1D-Graph Baseline Tool", graphBLTool()
End



//graphProfileUtility:  Select desired image plot and call this to allow slicing of horizontal or vertical traces
Function graphProfileUtility()
	//Error check
	string imagelist = imagenamelist(winname(0,1), ";")	//Return list of 2D images in the top graph window
	if(itemsinlist(imagelist, ";") == 0)					//Stop if no image plots in top window
		Print "(no images found in top graph!)"
		return 0
	endif
	if(strsearch(controlnamelist(winname(0,1)), "profile",0) != -1)	//Stop if profile buttons already setup in window
		return 0
	endif
	//Search here for other running graph utilities on this window here, if needed, so can quit them or abort
	
	//Setup global variables
	String/G profile_sourcegraph = winname(0,1)	//grab the name of the top graph window (user chose previously!)
	String/G profile_sourcewave				//holds the source image wave name
	if(itemsinlist(imagelist, ";") == 1)
		//If there's only one image wave, then grab it
		profile_sourcewave =  stringfromlist(0, imagenamelist(profile_sourcegraph, ";"))
	else
		//If there's more than one, then prompt the user to choose one of them
		string sourcewave
		Prompt sourcewave, "Choose source wave:", popup, imagenamelist(profile_sourcegraph, ";")
		DoPrompt "2D Graph Profile Utility", sourcewave
		profile_sourcewave = sourcewave
	endif
	variable/G profile_flag_H = 0				//flag for horiz profile (truth)
	variable/G profile_flag_V = 0				//flag for vert profile (truth)
	variable/G profile_xindex					//crosshair x point index
	variable/G profile_yindex					//crosshair y point index
	variable/G profile_xdelta = DimDelta($profile_sourcewave,0)	//row scale factor
	variable/G profile_ydelta = DimDelta($profile_sourcewave,1)	//column scale factor
	variable/G profile_xstart = DimOffset($profile_sourcewave,0)	//row starting value
	variable/G profile_ystart = DimOffset($profile_sourcewave,1)	//column starting value
	variable/G profile_xnumpts = DimSize($profile_sourcewave,0)	//row size in points
	variable/G profile_ynumpts = DimSize($profile_sourcewave,1)	//column size in points
	
	//Init crosshairs to center of graph (but make a valid index number)
	profile_xindex = round(profile_xnumpts / 2)
	profile_yindex = round(profile_ynumpts / 2)
	
	//Add green crosshairs (horiz and vert lines), which can be quick-dragged
	make/o/n=6 hairx={-inf,0,inf,0,0,0}, hairy={0,0,0,-inf,0,inf}
	appendtograph/C=(0,65535,0) hairy vs hairx
	ModifyGraph offset={(profile_xstart + profile_xdelta * profile_xindex), (profile_ystart + profile_ydelta * profile_yindex)}, quickdrag=1
	
	//Setup Buttons
	Button closeprofile proc=graphProfileButton,title="Close", fstyle=1, pos={0,0}, size={50,14}
	Button saveprofile proc=graphProfileButton,title="Save Profile", pos={50,0}, size={100,14}
	Button vertprofile proc=graphProfileButton,title="V", pos={150,0}, size={20,14}
	Button goleft proc=graphProfileButton,title="\W546", pos={170,0}, size={20,14}
	Button goright proc=graphProfileButton,title="\W549", pos={190,0}, size={20,14}
	Button horizprofile proc=graphProfileButton,title="H", pos={210,0}, size={20,14}
	Button goup proc=graphProfileButton,title="\W517", pos={230,0}, size={20,14}
	Button godown proc=graphProfileButton,title="\W523", pos={250,0}, size={20,14}
	//PopupMenu choosewave proc=graphProfileButton,title="",pos={270,0},size={100,14}
	//PopupMenu choosewave,mode=1,bodyWidth= 100,popvalue="-"//,value= #getDataTypes()
	
	//No graph is displayed initially, until user selects V or H
End

//This function does the work for graphProfileUtility when the user initiates an action
Function graphProfileButton(ctrlname): ButtonControl
	string ctrlname
	
	//Global Variables from graphProfileUtility()
	SVAR sourcegraph = profile_sourcegraph
	SVAR sourcewave = profile_sourcewave
	NVAR flag_H = profile_flag_H		//flag for horiz profile (truth)
	NVAR flag_V = profile_flag_V		//flag for vert profile (truth)
	NVAR xindex = profile_xindex		//crosshair x point index
	NVAR yindex = profile_yindex		//crosshair y point index
	NVAR xdelta = profile_xdelta 		//row scale factor
	NVAR ydelta = profile_ydelta 		//column scale factor
	NVAR xstart = profile_xstart 		//row starting value
	NVAR ystart = profile_ystart 		//column starting value
	NVAR xnumpts = profile_xnumpts 	//row size in points
	NVAR ynumpts = profile_ynumpts 	//column size in points
	//Global Variable for saving data:
	WAVE imagewave = imagenametowaveref(sourcegraph, sourcewave)
	
	//Catch a cursor drag here (quickdrag = 1):
	//NOTE:  Using Igor's <Readback ModifyStr> to parse TraceInfo data
	variable xdragoffset = GetNumFromModifyStr(TraceInfo("", "hairy", 0), "offset", "{", 0)
	variable ydragoffset = GetNumFromModifyStr(TraceInfo("", "hairy", 0), "offset", "{", 1)
	//turn into an index
	variable xdragindex = round((xdragoffset - xstart) / xdelta)
	variable ydragindex = round((ydragoffset - ystart) / ydelta)
	//TraceInfo only gives xdragoffset to a precision of five decimal points, 
	//so if xdelta is of comparable size or smaller, then only update xindex
	//to xdragindex if the change is significant!  Otherwise you'll have some cursor "snap" errors.
	if(abs(xdelta) > 0.00001)
		xindex = xdragindex	//ok to update b/c xdelta isn't small
	elseif(abs((xdragindex - xindex)*xdelta) > 0.00001)
		xindex = xdragindex	//only update for small xdelta if significant change!
	endif
	if(abs(ydelta) > 0.00001)
		yindex = ydragindex
	elseif(abs((ydragindex - yindex)*ydelta) > 0.00001)
		yindex = ydragindex
	endif
	
	strswitch(ctrlname)
		case "graphprofile":		//display a graph of the desired profile (no new wave created)
			DoWindow/K ProfileUtility		//Kill any previous graph version
			//Do vert-horiz specific tasks (labeling...) -- NOTE: need <Axis Utilities>
			//Make assumptions here about axis names...
			string dummy
			if((flag_V == 1) && (flag_H == 0))		//Vertical Profile
				Display/N=ProfileUtility $sourcewave [xindex][]	//Show new graph
				ModifyGraph/W=ProfileUtility mode=4	//Use lines and markers to make data points clear
				//Label name of source and type of cut
				TextBox/W=ProfileUtility/C/N=text2/F=0/B=1/A=LB/X=0.00/Y=100.00 "Source: " + sourcewave + "[" + num2istr(xindex) + "][]"
				TextBox/W=ProfileUtility/C/N=profile2/F=0/A=RB/X=0.00/Y=100.00/B=1 "Vert. profile: X = " + num2str(xindex*xdelta + xstart)
				
				//Label the y-axis - assuming have colorscale with name "text0", fix units key
				dummy = StringByKey("TEXT", AnnotationInfo(sourcegraph, "text0"))
				dummy = ReplaceString("\\\\", dummy, "\\")
				Label/W=ProfileUtility left, dummy
				
				//label the x-axis
				Label/W=ProfileUtility bottom AxisLabelText(sourcegraph, "left", SuppressEscaping=1)
			elseif((flag_V == 0) && (flag_H == 1))	//Horizontal Profile
				Display/N=ProfileUtility $sourcewave [][yindex]	//Show new graph
				ModifyGraph/W=ProfileUtility mode=4	//Use lines and markers to make data points clear
				//Label name of source and type of cut
				TextBox/W=ProfileUtility/C/N=text2/F=0/B=1/A=LB/X=0.00/Y=100.00 "Source: " + sourcewave + "[][" + num2istr(yindex) + "]"
				TextBox/W=ProfileUtility/C/N=profile2/F=0/A=RB/X=0.00/Y=100.00/B=1 "Horiz. profile, Y = " + num2str(yindex*ydelta + ystart)
				
				//Label the y-axis - assuming have colorscale with name "text0", fix units key
				dummy = StringByKey("TEXT", AnnotationInfo(sourcegraph, "text0"))
				dummy = ReplaceString("\\\\", dummy, "\\")
				Label/W=ProfileUtility left, dummy
				
				//label the x-axis
				Label/W=ProfileUtility bottom AxisLabelText(sourcegraph, "bottom", SuppressEscaping=1)
			endif
			break
		case "vertprofile":		//set flags for vertical profile
			flag_V = 1
			flag_H = 0
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "horizprofile":	//set flags for horizontal profile
			flag_V = 0
			flag_H = 1
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "goleft":			//move crosshairs left
			xindex -= 1
			ModifyGraph/W=$sourcegraph offset(hairy)={(xstart + xdelta * xindex), (ystart + ydelta * yindex)}
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "goright":		//move crosshairs right
			xindex += 1
			ModifyGraph/W=$sourcegraph offset(hairy)={(xstart + xdelta * xindex), (ystart + ydelta * yindex)}
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "goup":			//move crosshairs up
			yindex += 1
			ModifyGraph/W=$sourcegraph offset(hairy)={(xstart + xdelta * xindex), (ystart + ydelta * yindex)}
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "godown":		//move crosshairs down
			yindex -= 1
			ModifyGraph/W=$sourcegraph offset(hairy)={(xstart + xdelta * xindex), (ystart + ydelta * yindex)}
			graphProfileButton("graphprofile")	//Update the graph
			break
		case "saveprofile":	//let's the user save a copy of the current profile, and makes a nice graph of the copy
			string destname
			If((flag_V == 1) && (flag_H == 0))		//Vertical Profile
				destname = sourcewave + "_profile_V" + num2istr(xindex)
				Prompt destname, "Enter name for destination 1d wave to save " + sourcewave + "[" + num2istr(xindex) + "][]:"
			elseif((flag_V == 0) && (flag_H == 1))	//Horizontal Profile
				destname = sourcewave + "_profile_H" + num2istr(yindex)
				Prompt destname, "Enter name for destination 1d wave to save " + sourcewave + "[][" + num2istr(yindex) + "]:"
			else
				return 0		//no profile selected, so don't do anyting (soft abort)
			endif
			DoPrompt "Save 2D Graph Profile", destname
			
			If((flag_V == 1) && (flag_H == 0))		//Vertical Profile
				//Make the profile wave
				make/n=(ynumpts) $PossiblyQuoteName(destname)
				wave pw = $PossiblyQuoteName(destname)
				setscale/P x ystart, ydelta, pw
				pw[] = imagewave [xindex][p]
				
				//Display it will all the frills possible
				Display/I/W=(4.5, 0, 9, 2.5) $PossiblyQuoteName(destname)
				ModifyGraph mode=4		//Use lines and markers to make data points clear
				//Label name of source and type of cut
				TextBox/C/N=text2/F=0/B=1/A=LB/X=0.00/Y=100.00 "Source: " + sourcewave + "[" + num2istr(xindex) + "][]"
				TextBox/C/N=profile2/F=0/A=RB/X=0.00/Y=100.00/B=1 "Vert. profile: X = " + num2str(xindex*xdelta + xstart)
				
				//Label the y-axis - assuming have colorscale with name "text0", fix units key
				dummy = StringByKey("TEXT", AnnotationInfo(sourcegraph, "text0"))
				dummy = ReplaceString("\\\\", dummy, "\\")
				Label left, dummy
				
				//label the x-axis
				Label bottom AxisLabelText(sourcegraph, "left", SuppressEscaping=1)
				
				Print "-- Profile saved: " + destname + " = " +  sourcewave + "[" + num2istr(xindex) + "][]"
			elseif((flag_V == 0) && (flag_H == 1))	//Horizontal Profile
				//Make the profile wave
				Make/n=(xnumpts) $PossiblyQuoteName(destname)
				wave pw = $PossiblyQuoteName(destname)
				setscale/P x xstart, xdelta, pw
				pw[] = imagewave [p][yindex]
				
				//Display it will all the frills possible
				Display/I/W=(4.5, 0, 9, 2.5) $PossiblyQuoteName(destname)
				ModifyGraph mode=4	//Use lines and markers to make data points clear
				//Label name of source and type of cut
				TextBox/C/N=text2/F=0/B=1/A=LB/X=0.00/Y=100.00 "Source: " + sourcewave + "[][" + num2istr(yindex) + "]"
				TextBox/C/N=profile2/F=0/A=RB/X=0.00/Y=100.00/B=1 "Horiz. profile, Y = " + num2str(yindex*ydelta + ystart)
				
				//Label the y-axis - assuming have colorscale with name "text0", fix units key
				dummy = StringByKey("TEXT", AnnotationInfo(sourcegraph, "text0"))
				dummy = ReplaceString("\\\\", dummy, "\\")
				Label left, dummy
				
				//label the x-axis
				Label bottom AxisLabelText(sourcegraph, "bottom", SuppressEscaping=1)
				
				Print "-- Profile saved: " + destname + " = " +  sourcewave + "[][" + num2istr(yindex) + "]"
			endif
			break
		case "closeprofile":		//close the utility by removing crosshairs, all buttons, global variables
			if(strsearch(tracenamelist(winname(0,1),";",1),"hairy",0) != -1)
				removefromgraph $"hairy"
			endif
			//Remove all buttons
			killcontrol closeprofile
			killcontrol saveprofile
			killcontrol vertprofile
			killcontrol horizprofile
			killcontrol goleft
			killcontrol goright
			killcontrol goup
			killcontrol godown
			//Remove global variables
			killwaves/Z hairx, hairy
			killstrings/Z sourcegraph, sourcewave
			killvariables/Z flag_V, flag_H, xindex, yindex, xdelta, ydelta, xstart, ystart, xnumpts, ynumpts
			break
	endswitch
End

//######################################################################
//graphBLTool - removes baseline signal from 1D graphs...
Function graphBLTool()
	//Error check
	string tracelist = tracenamelist("", ";", 1)	//Return list of traces in the top graph window
	if(itemsinlist(tracelist, ";") == 0)					//Stop if no traces in top window
		Print "(no traces found in top graph!)"
		return 0
	endif
	if(strsearch(controlnamelist(winname(0,1)), "bkgnd",0) != -1)	//Stop if buttons already setup in window
		return 0
	endif
	//Search here for other running graph utilities on this window here, if needed, so can quit them or abort
	
	//Setup global variables
	String/G bkgnd_sourcegraph = winname(0,1)	//grab the name of the top graph window (user chose previously!)
	String/G bkgnd_sourcewave				//holds the source  wave name
	if(itemsinlist(tracelist, ";") == 1)
		//If there's only one  wave, then grab it
		bkgnd_sourcewave =  stringfromlist(0, tracenamelist(bkgnd_sourcegraph, ";", 1))
	else
		//If there's more than one, then prompt the user to choose one of them
		string sourcewave
		Prompt sourcewave, "Choose source wave:", popup, tracenamelist(bkgnd_sourcegraph, ";", 1)
		DoPrompt "1D Graph Background Utility", sourcewave
		bkgnd_sourcewave = sourcewave
	endif
	//Setup mask for fit to wave
	//WAVE w = $sourcewave
	Duplicate/O $bkgnd_sourcewave $("mask_" + bkgnd_sourcewave)
	WAVE mask = $("mask_" + bkgnd_sourcewave)
	mask = 1
	
	//Save a backup wave...
	Duplicate/O $bkgnd_sourcewave $("raw_" + bkgnd_sourcewave)
	Printf "-- Saved backup of original:  \t%s = %s\r", "raw_" + bkgnd_sourcewave, bkgnd_sourcewave
	
	//Setup Cursors
	//ShowInfo		//show cursor info (optional)
	Cursor/W=$bkgnd_sourcegraph/A=1/C=(0, 65535, 0)/P A, $bkgnd_sourcewave, 1							//Cursor A on first point of wave
	Cursor/W=$bkgnd_sourcegraph/A=1/C=(0, 65535, 0)/P B, $bkgnd_sourcewave, numpnts($bkgnd_sourcewave) - 1	//Curson B on last point of wave
	
	//Setup Buttons
	Button closebaseline proc=graphBLToolbutton,title="Close", fstyle=1, pos={0,0}, size={50,25}
	Button maskbaseline proc=graphBLToolbutton,title="Mask", pos={50,0}, size={50,25}
	Button fitbaseline proc=graphBLToolbutton,title="Fit Baseline", pos={100,0}, size={75,25}
	Button normbaseline proc=graphBLToolbutton,title="Norm", pos={175,0}, size={50,25}
	Button reducebaseline proc=graphBLToolbutton,title="Reduce", pos={235,0}, size={50,25}
End

//This function does the work for graphBkgndTool when the user initiates an action
Function graphBLToolbutton(ctrlname): ButtonControl
	string ctrlname
	
	//Global Variables from graphProfileUtility()
	SVAR sourcegraph = bkgnd_sourcegraph
	SVAR sourcewave = bkgnd_sourcewave
	WAVE W_coef, W_sigma					//results from fits
	//Global Variable for saving data:
	WAVE w = tracenametowaveref(sourcegraph, sourcewave)
	string maskwave = "mask_" + sourcewave
	WAVE mask = $maskwave				//mask for fitting
	
	//Cursor information
	variable csrAx = xcsr(A, sourcegraph)	//store x value of cursor A
	variable csrAy = vcsr(A, sourcegraph)	//store y value of cursor A
	variable csrBx = xcsr(B, sourcegraph)
	variable csrBy = vcsr(B, sourcegraph)
	variable csrAp = pcsr(A, sourcegraph)	//store p value of cursor A
	variable csrBp = pcsr(B, sourcegraph)	//store p value of cursor B
	variable polarity = pcsr(B, sourcegraph) - pcsr(A, sourcegraph)	//Difference between point value of cursor positions
	
	variable xdelta = csrBx - csrAx 
	variable ydelta = csrBy - csrAy
	variable slope = ydelta / xdelta
	variable offset = 0.5 * (csrAy + csrBy)		//average y-value of cursors, for normalizing
	
	//Error check cursor information
	If(polarity == 0)
		Print "-- (cursors are ontop of each other!)"
		return 0		//soft abort
	endif
	if(polarity < 0)
		//User switched cursor ordering!!!!
		slope *= 1
	endif	//otherwise, have expected ordering of cursors
	
	strswitch(ctrlname)
		case "maskbaseline":		//Toggles points between cursors to be included or excluded from Bkgnd Fit using mask wave
			//swap all points between cursors to be opposite of the average
			if(round(mean(mask,csrAx,csrBx)))
				mask[csrAp,csrBp] = 0.0
			else
				mask[csrAp,csrBp] = 1.0
			endif
			
			//Update coloring to reflect the mask:
			ModifyGraph/W=$sourcegraph zColor($sourcewave)={mask,-1,1,Grays,1}
			break
		case "fitbaseline":			
			//Fit the data with a quadratic curve, using the wavemask.  Appends fit to graph.
			CurveFit/Q/NTHR=0 poly 5,  $sourcewave /M=$maskwave /D //quartic
		//	CurveFit/Q/NTHR=0 poly 4,  $sourcewave /M=$maskwave /D //cubic
		//	CurveFit/Q/NTHR=0 poly 3,  $sourcewave /M=$maskwave /D //quadratic
		//	CurveFit/Q/NTHR=0 line,  $sourcewave /M=$maskwave /D //line
			Printf "-- Fit of baseline: Chisq = %g.\r", V_chisq
			break
		case "normbaseline":		
			//ASSUME just fit with quadratic using fitbkgnd button!
			
			//Save a backup wave...
			//Duplicate/O w $("raw_" + sourcewave)
			//Printf "-- Saved backup of original:  \r\t%s = %s\r", "raw_" + sourcewave, sourcewave
			
			//Divide the background fit...
			w /= W_coef[0] + W_coef[1]*x + W_coef[2]*x^2 + W_coef[3]*x^3 + W_coef[4]*x^4  //quartic
			Printf "-- Normalized:  \r\t%s /= (%g ± %g) + (%g ± %g)*x + (%g ± %g)*x^2 + (%g ± %g)*x^3 + (%g ± %g)*x^4\r", sourcewave, W_coef[0], W_sigma[0],W_coef[1], W_sigma[1],W_coef[2], W_sigma[2],W_coef[3], W_sigma[3],W_coef[4], W_sigma[4]
		//	w /= W_coef[0] + W_coef[1]*x + W_coef[2]*x^2 + W_coef[3]*x^3  //cubic
		//	Printf "-- Normalized:  \r\t%s /= (%g ± %g) + (%g ± %g)*x + (%g ± %g)*x^2 + (%g ± %g)*x^3\r", sourcewave, W_coef[0], W_sigma[0],W_coef[1], W_sigma[1],W_coef[2], W_sigma[2],W_coef[3], W_sigma[3]
		//	w /= W_coef[0] + W_coef[1]*x + W_coef[2]*x^2  //quadratic
		//	Printf "-- Normalized:  \r\t%s /= (%g ± %g) + (%g ± %g)*x + (%g ± %g)*x^2\r", sourcewave, W_coef[0], W_sigma[0],W_coef[1], W_sigma[1],W_coef[2], W_sigma[2]
		//	w /= W_coef[0] + W_coef[1]*x  //line
		//	Printf "-- Normalized:  \r\t%s /= (%g ± %g) + (%g ± %g)*x\r", sourcewave, W_coef[0], W_sigma[0],W_coef[1], W_sigma[1]
			
			//Remove old fit trace from graph (since source was just modified!).
			RemoveFromGraph $("fit_" + sourcewave)
			//Remove mask coloring:
			ModifyGraph/W=$sourcegraph rgb=(0,0,0),zColor($sourcewave)=0
			//Add green line through 1.0 to show where full transmission is:
			SetDrawEnv ycoord= left,linefgc= (0,65535,0);DelayUpdate;DrawLine 0,1,1,1
			break
		case "reducebaseline":	//restricts wave to area between cursor
			string tempwave1 = "temp_" + sourcewave
			string tempwave2 = "temp_" + maskwave
			Duplicate/O $sourcewave $tempwave1
			Duplicate/O $maskwave $tempwave2
			Duplicate/O/R=[csrAp,csrBp] $tempwave1 $sourcewave
			Duplicate/O/R=[csrAp,csrBp] $tempwave2 $maskwave
			Printf "-- Reduced x-range to (%g, %g), p-range to [%g, %g].\r", csrAx,csrBx,csrAp,csrBp
			killwaves  $tempwave1, $tempwave2		//remove the temporary wave...
			break
		case "closebaseline":		//close the utility by removing cursors, all buttons, global variables
			//HideInfo		//hide cursor info (optional)
			Cursor/M/K A
			Cursor/M/K B
			//Remove all buttons
			killcontrol closebaseline
			killcontrol maskbaseline
			killcontrol fitbaseline
			killcontrol normbaseline
			killcontrol reducebaseline
			//Remove global variables
			killstrings/Z sourcegraph, sourcewave
			//killvariables/Z flag_V, flag_H, xindex, yindex, xdelta, ydelta, xstart, ystart, xnumpts, ynumpts
			break
	endswitch
End