#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 3.0	// This File's Version

//####[ Expt_Analysis ]#################################################
//	Bart McGuyer, Department of Physics, Princeton University 2008
// 
//	Expt_Analysis provides routines and conventions for data management, 
//	archiving, and graphing, and is intended to work together with 
//	Expt_Data to simplify data taking. While Expt_Data is meant to be 
//	specialized for a particular experiment or computer, this file is 
//	meant to be independent, and to work on any computer.  Also includes 
//	routines to work with the command history and notebooks.  
// 
//	SEE the "Explanation of Wave Conventions" following the table of contents
//	below to learn more about what this file does.  
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
//	Assumptions:
//	-- Igor Pro v5 and above
//	-- This file is meant to be independent of other procedures, so it can function on multiple computers.
//	
//	Version Notes:
//	-- v3.0: 12/15/2011 - Slight modification before posting at www.igorexchange.com. 
//
//	Possible Future Work:
//	-- Figure out how to kill non-minimized visible graphs -- see MoveWindow? 
//	-- Maybe add support for Multi-peak fit routines from Igor?
//	-- Maybe add support for "fit_" waves in shownum()... (ex: append to appropriate graphs)?
//	
//	Notes:
// -- This file usually exists on multiple computers with slight changes...
//	-- Default IGOR fonts for graphs and files are Arial (PC) and Geneva (Mac).
//	-- To change the default graph settings, edit showwaves and showwaterfall.  
//	-- Procedure files are best viewed with monospace fonts (ex: 12pt Consolas, 10pt Monaco).
// -- Here are two 72 char linerules (old printing width for monospace fonts):  
//######################################################################
//----------------------------------------------------------------------
//	
//	####[ Table of Contents ]####
//	Functions:						Description:
//		nextwave							returns next waveid to use for new waves, ex: in sweeping routines like do1d, etc.
//		shownum							show all waves with a specified waveid, except IGOR fits
//		savenum							saves all waves (even fits) with waveid as IGOR text files (windows convention), with popup for options
//		loadnum							loads all data (IGOR text files) with waveid stored inside a folder (chosen by popup menu)
//		listnum							returns list of waves with given waveid, minus IGOR fits
//		appendnum						appends similar waves with waveid to top graph (even fits)
//		showwaves						shows all waves in a given wave list (or a name)
//		showwaterfall					shows waterfall plots of 2d waves with given waveid
//		getAxisLabel					returns the label corresponding to the given axis for the given wave name
// ---- Wavenote Utilities ----
//		shownote							prints wavenotes for all waves with a given waveid, except IGOR fits
//		editnote							edit wavenote for given wave, changing/appending a key:value; in the stringlist
//		editnotes						edit wavenotes for waves with waveid (not fits), changing/appending a key:value; in the stringlist 
//		showcmnt							prints user comment from wavenotes for waves with waveid (not fits), which is the same for all waves (not fits)
//		editcmt							edit user comment for waves with waveid (not fits), for fixing mistakes in wave comments
//	---- History Utilities ----
//		newday							Use this at start of a new day to print a clear separation in the History
//		header							prints seaparating "headline" message in History
//		printError						standard way to print error alerts to history (channels error recording)
//		div								put big vertical space in history
//		msg								Use this to make a message that's hard to miss in History
//	---- Notebook Utilities ----
//		nbAddParagraph					Appends text to the end of a notebook as a paragraph (adds a carriage return)
//		nbGetParagraph					Returns a paragraph in a notebook
//		nbSetParagraph					Replaces an existing paragraph in a notebook
//		nbNumParagraph					Returns the number of paragraphs in a notebook (doesn't count empty final paragraph)
//	---- Graph Utilities ----
//		graphPosition					(Flexible) graph location and sizing convention for do1d, ...
//		graphAnnTopLeft				annotate graph at top left (typically for 1-line wave name)
//		graphAnnTopRight				annotate graph at top right (typically for 1-line wavenote comments)
//		graphKillTop					Kills top visible graph (without saving macro).
//		graphKillAll					Kills ALL visible graphs (even hidden and minimized graphs, without saving macro's).
//		graphHideAll					Hides all visible graphs (hidden != minimized) without killing them.
//		graphUnhideAll					Unhides ALL graphs (hidden != minimized).

//######################################################################
//	== Explanation of Wave Conventions ==
//	
//	Together, Expt_Analysis and Expt_Data help you to create and manage  
//	data waves following a wave-naming convention that indicates the data
//	variables ("idstr" or stream) and includes a unique serial number 
//	("waveid" or num).  
//	Metadata about the wave is stored in the wave's wavenote as a 
//	standard IGOR stringlist.  This enables, for example, waves to be 
//	graphed with axis labels automatically included.
//	
//	(1) Wave Naming:
//		Basic wave name:	"<Datatype><Xaxistype>[<Yaxistype>[<Zaxistype>[<Taxistype>]]]_<waveid>"
//	Notes:  
//	-- The [...] above mean optional, and are not indexing notation!
//	-- Ex: sweeping "Out1" while measuring "In2" with waveid #5 would be "In2Out1_5".
//	-- The <...type> are reffered to as an "idstr" or "stream" (see Expt_Data).  
//	-- The waveid is a unique serial number (integer, >= 1) for all waves created during the same data-taking command.
//	(2) Wave Axes:
//		Point indexing:  wave[p][q][r][s] = data
//		Scaled indexing:	wave(x)(y)(z)(t) = data
//	Notes:  
//	-- TABLE of IGOR and Expt_Analysis axes conventions: 
//			IGOR-------------------------	Expt_Analysis----
//			axis	axis		point		scaled	axis			axis
//			type	number	index		index		idstr			key/name
//			"data"	-1		n/a		n/a		Datatype		d
//			"row"		0		p			x			Xaxistype	x
//			"column"	1		q			y			Yaxistype	y
//  		"layer"	2		r			z			Zaxistype	z
//  		"chunk"	3		s			t			Taxistype	t
//	-- In 1D waves, the y-values are often referred to as "D values", so I've chosen to use D to represent the "data" axis type (vs. sweeping axes)
//	-- The general hierarchy for sweeping in terms of sweep speed is x > y > z > t
//		- This way the x-axis is the fastest in all data
//		- Ex: in do2d, x = fast inner loop and y = slow outer loop
//  		- This way, 2D waves display correctly as waterfall plots
//	-- NOTE: the number column follows Igor's convention.
//	-- IGOR dimension labels (e.g., getDimLabel, or Wave Units) aren't used for axes labeling.
//	
//	(3) Wavenote Metadata:
//	-- Important information about a wave is stored in its wavenote.  
//		- Usually this is done at creation by a sweeping routine (ex: do1d) 
//		- The information can be edited or added later
//	--	The wavenote information is stored in a typical IGOR stringlist:  "key1:val1;key2:val2;key3:val3;"
//	-- Axis label information for graphing is included, so if getLabel changes the axis label doesn't.
//	-- Wavenotes are copied when waves are duplicated or are exported/imported as IGOR text files.
//		- So wavenotes are preserved and no information is lost during these processes.
//	-- TABLE of Metadata used so far:  
//			KEY			VALUE
//			waveid		original waveid for this wave (helps to keep track when you duplicate or rename waves)
//			cmd			verbatim full command that generated this wave (ex: 'do1d("time",0,10,10,0.1)')
//			date			date wave created (from date())
//			time			time wave created (from time())
//			d				Datatype idstr
//			x				Xaxistype idstr
//			y				Yaxistype idstr (only include if applicable)
//			z				Zaxistype idstr (only include if applicable)
//			t				Taxistype idstr (only include if applicable)
//			dlabel		axis label for data axis
//			xlabel		axis label for x axis
//			ylabel		axis label for y axis (only include if applicable)
//			zlabel		axis label for z axis (only include if applicable)
//			tlabel		axis label for t axis (only include if applicable)
//			comment		"user comment", as entered in DataTypes panel (global variable set by panel) or manually, typically displayed on graphs in upper right.
// 
//	(4) Exporting/Importing Data as Files:
//	This convention is compatible with IGOR text files, since that format 
//	preserves wavenotes.  You can exchange waves between experiments by 
//	exporting/importing as IGOR text files.  See savenum() and loadnum().
//
//	(5) Important Notes:
//	-- Idstr are not case-sensitive since IGOR string matching is not case sensitive (ex: stringmatch, stringbykey, strswitch).
//	-- Avoid idstr's that would give liberal wave names, since liberal names are troublesome in IGOR.
//	-- Only 1d and 2d waves are fully supported for the moment.
//	-- ... axis labels are kept in wavenotes, so that changing getLabel doesn't affect wave information.
//######################################################################

//getAxisLabel:  returns the label corresponding to the given axis for the given wave name
function/S getAxisLabel(wavestr,axisname)
	string wavestr		//wavename
	string axisname	//d,x,y,z,t
	//NOTE:  Before version 2, getAxisLabel used to input an axis number and convert it 
	//to an axis name with this convention: 0 = data, 1 = x, 2 = y, 3 = z, 4 = t (Igor's convention + 1).
	
	//could test waveexists
	
	string wavenote = note($wavestr)
	
	if(strsearch(wavenote,axisname + "label:",0)!=-1)
		//YES - found axis label key in wavenote, return it
		return StringByKey(axisname + "label", wavenote)	
	else	
		//NO - axis label not found in wavenote
		printError("getAxisLabel()", axisname + "-axis label missing in wavenote.")
		return ""//error catch is in getlabel
		//Legacy behavior was to reconstruct from getlabel, but in version 2 moved getlabel to Expt_Data:
		//printError("getAxisLabel()", axisname + "-axis label missing in wavenote; reconstruct from idstr.")
		//return getlabel(StringByKey(axisname,wavenote))//error catch is in getlabel
	endif
End

//nextwave:  returns next waveid to use for new waves, ex: in sweeping routines like do1d, etc.
//-- 11/17/09 FIXED to deal with numerically named waves that are fit, leading to ex: "fit_1234_11" so that 1234 is not read as an index!
function nextwave()
	string waves=wavelist("!fit_**",";","")
	variable i=itemsinlist(waves,"_"),lastwave=0,num
	do
		i -= 1
		num=str2num(stringfromlist(i,waves,"_"))
		lastwave=(numtype(num) ? lastwave : max(lastwave,num))
	while(i>0)
	return lastwave+1
end

//listnum:  returns list of waves with given waveid, minus IGOR fits
function/S listnum(num)
	variable num
	
	string list = wavelist(("*_" + num2istr(num)), ";", "")//All waves with waveid
	string fitlist = wavelist(("fit_*_" + num2istr(num)), ";", "")//IGOR fits with waveid
	list = removefromlist(fitlist,list,";")
	
	return list
end

//shownum:  show all waves with a specified waveid, except IGOR fits
function shownum(num)
	variable num
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list,";"))			//If nothing found...
		return 0					//"nicer" alternative to abort
	//elseif(itemsinlist(list,";")>1)		//If multiple items...
		//Remove undesired items from list here using removefromlist()...
	endif
	showwaves(list)
	//Append Igor fits here?
end

//showwaves:  shows all waves in a given wave list (or a name)
function showwaves(list)
	string list
	string item, comment
	variable ii
	
	for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
		item = stringfromlist(ii, list, ";")
		switch(wavedims($item))	//Number of dimensions in the wave
			case 1:	//1d wave
				Display $item
				Label bottom getAxisLabel(item,"x")
				Label left getAxisLabel(item,"d")
				ModifyGraph notation = 1				//use scientific notation
				break
			case 2:  //2d wave
				Display; AppendImage $item
				Label bottom getAxisLabel(item,"x")
				Label left getAxisLabel(item,"y")
				ModifyImage $item ctab= {*,*,YellowHot,0}		//default color scale
				ColorScale/C/N=text0/F=0/A=RC/E/X=0.00/Y=0.00 image=$item, getAxisLabel(item,"d")	//Attach color scale legend
				ColorScale/C/N=text0 notation=1		//use scientific notation
				ModifyGraph notation = 1				//use scientific notation
				Cursor/M/C=(0,65535,0) A;Cursor/M/C=(0,65535,0) B	//Make the cursors green (default is hard to read!)
				break
			default:	//error catch -- 3d, 4d waves
				printError("showwaves","Bad wave dimension (3D or 4D)!")
				return 0			//soft abort
		endswitch
		graphAnnTopLeft(item)//Put the wave name on the graph
		
		comment = StringByKey("comment", note($item))
		if(!stringmatch(comment, ""))//If exists and not null, add user comment to upper right
			graphAnnTopRight(comment)
		endif
		
		//AutoPositionWindow/M=0	//Spread multiple windows out...
	endfor
end

//showwaterfall:  shows waterfall plots of 2d waves with given waveid
function showwaterfall(num)
	variable num
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list,";"))			//If nothing found...
		return 0					//"nicer" alternative to abort
	endif
	
	string item, comment
	variable ii
	
	for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
		item = stringfromlist(ii, list, ";")
		switch(wavedims($item))	//Number of dimensions in the wave
			case 2:  //2d wave
				NewWaterfall $item
				Label bottom getAxisLabel(item,"x")
				Label left getAxisLabel(item,"d")
				Label right getAxisLabel(item,"y")
				Cursor/M/C=(0,65535,0) A;Cursor/M/C=(0,65535,0) B //Make the cursors green (default is hard to read!)
				ModifyGraph notation = 1				//use scientific notation
				break
			default:	//error catch -- 1d, 3d, 4d waves
				//printError("showwaterfall","Bad wave dimension (not 2D)!")
				break
		endswitch
		graphAnnTopLeft(item)//Put the wave name on the graph
		
		comment = StringByKey("comment", note($item))
		if(!stringmatch(comment, ""))//If exists and not null, add user comment to upper right
			graphAnnTopRight(comment)
		endif
		
		//AutoPositionWindow/M=0	//Spread multiple windows out...
	endfor
end

//appendnum:  appends similar waves with waveid to top graph (even fits)
function appendnum(num)
	variable num
	
	//get info about top graph (to be appended to)
	string sourcegraph = winname(0,1)	//grab the name of the top graph window (user chose previously!)
	string tracelist = tracenamelist("", ";", 1)	//Return list of 1D traces in the top graph window
	string imagelist = imagenamelist(winname(0,1), ";")	//Return list of 2D images in the top graph window
	
	string list = wavelist(("*_" + num2istr(num)), ";", "")
	string item
	variable ii
	
	if(!itemsinlist(list,";"))//If nothing found to append...
		return 0			//"nicer" alternative to abort
	else								//One or more items to append
		//choose amongst the waves which to append...
		for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
			item = stringfromlist(ii, list, ";")
			print item
			//test if dimensions match the graph type
			if(!stringmatch(tracelist, "") && (wavedims($item) == 1))
				//YES - 1D wave to append!
				AppendToGraph/W=$sourcegraph $item
			elseif(!stringmatch(imagelist, "") && (wavedims($item) == 2))
				//YES - 2D wave to append!
				AppendImage/W=$sourcegraph $item
				ModifyImage $item ctab= {*,*,YellowHot,0}	//default color scale for images
			endif
			
			//update textbox to reflect all waves?
		endfor
	endif
end

//savenum:  saves all waves (even fits) with waveid as IGOR text files (windows convention), with popup for options
function savenum(num)
	variable num
	
	string list = wavelist(("*_" + num2istr(num)), ";", "")
	if(!itemsinlist(list,";"))			//If nothing found...
		Print "-- No wave(s) found to save!"
		return 0			//"nicer" alternative to abort
	endif
	
	string item
	variable ii
	
	for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
		item = stringfromlist(ii, list, ";")
		//save as Igor text file, Windows convention, wavename as filename, prompt for directory
		Save/T/M="\r\n" $item as item + ".itx"	
		Print "-- Saved wave " + item + " as Igor text file (Windows convention)."//still prints even if didn't save (user cancelled)
	endfor
end

//loadnum:  loads all data (IGOR text files) with waveid stored inside a folder (chosen by popup menu)
function loadnum(num)
	variable num
	
	// get pathname from user via popup
	NewPath/O loadnumPath
	string pathname = "loadnumPath"

	variable index = 0	//file index	
	string filename		//captured filename
	Variable result
	do	//loop files in folder
		filename = indexedFile($pathname, index, ".itx")//find next IGOR text file 
		if(strlen(filename)==0)	//no more files?
			break					//break out of loop
		endif
		
		if(stringmatch(filename,"*_"+num2istr(num)+".itx"))//check if waveid=num
			LoadWave/Q/O/T/P=$pathname filename//load wave, overwrite old wave if need to.  
			if(V_flag==0)
				//trouble?
				printError("loadnum","Trouble loading wave from " + filename)
			else
				Print "-- Loaded wave from " + filename + "."
			endif
		endif
		
		index += 1
	while(1)
end

//####[ Wavenote Utilities ]############################################

//shownote:  prints wavenotes for all waves of a given waveid, except IGOR fits
function shownote(num)
	variable num
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list,";"))			//If nothing found...
		return 0					//"nicer" alternative to abort
	endif
	
	string item
	variable ii
	
	for(ii = 0; ii < itemsinlist(list,";"); ii += 1)
		item = stringfromlist(ii, list, ";")
		Print "-- Wavenote for " + item + ":"
		Print "\t" + note($item)
	endfor
end

//editnote:  edit wavenote for given wave, changing/appending a key:value; in the stringlist
Function editnote(wname, key, value)
	string wname	//name of wave with wavenote to edit
	string key		//which key in the wavenote stringlist to change values
	string value	//new value for the key
	
	Note/K $wname, ReplaceStringByKey(key, note($wname), value)
end

//editnotes:  edit wavenotes for waves with waveid (not fits), changing/appending a key:value; in the stringlist
//NOTE: Beware! This edits all waves with waveid, and their wavenotes might have different values for the same key on purpose! (ex: dlabel).
Function editnotes(num, key, value)
	variable num	//waveid of waves with wavenotes to be edited
	string key		//which key in the wavenote stringlist to change values
	string value	//new value for the key
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list, ";"))			//If nothing found...
		Print "-- No wave(s) with wavenotes to edit!"
		return 0					//"nicer" alternative to abort
	endif
	
	//update wavenotes for all waves with wavenum, appends "key:value;" if didn't exist before:
	variable ii
	for(ii = 0; ii < itemsinlist(list, ";"); ii += 1)
		Note/K $stringfromlist(ii, list, ";"), ReplaceStringByKey(key, note($stringfromlist(ii, list, ";")), value)
	endfor
end

//showcmnt:  prints user comment from wavenotes for waves with waveid, which is the same for all waves (not fits)
function showcmt(num)
	variable num
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list,";"))			//If nothing found...
		Print "-- No wave(s) with user comments to show!"
		return 0					//"nicer" alternative to abort
	endif
	
	//Return comment from wavenote of first item found
	string item = stringfromlist(0, list, ";")
	Print "-- User Comment for wave(s) # " + num2istr(num) + ":\t\t" + StringByKey("comment", note($item))
end

//editcmt:  edit user comment for waves with waveid (not fits), for fixing mistakes in wave comments
function editcmt(num)
	variable num
	
	string list = listnum(num)//waves with waveid, minus IGOR fits
	if(!itemsinlist(list, ";"))			//If nothing found...
		return 0					//"nicer" alternative to abort
	//elseif(itemsinlist(list, ";")>1)		//If multiple items...
		//Remove undesired items from list here using removefromlist()...
	endif
	
	//Return comment from wavenote of first item found
	string firstitem = stringfromlist(0, list, ";")
	string cmt = StringByKey("comment", note($firstitem))
	Print "-- Old User Comment for wave(s) # " + num2istr(num) + ":\t\t" + cmt
	
	//Prompt user for updated comment
	Prompt cmt, "Edit Comment for wave(s) # " + num2istr(num) + ":"
	DoPrompt "Edit Wave Comment", cmt
	
	//update comments for all waves with wavenum with new comment:
	variable ii
	for(ii = 0; ii < itemsinlist(list, ";"); ii += 1)
		Note/K $stringfromlist(ii, list, ";"), ReplaceStringByKey("comment", note($stringfromlist(ii, list, ";")), cmt)
	endfor
	
	//Show new version of comment
	cmt = StringByKey("comment", note($firstitem))
	Print "-- New User Comment for wave(s) # " + num2istr(num) + ":\t\t" + cmt
end

//####[ History Utilities ]#############################################

//newday:  Use this at start of a new day to prints a clear separation in History
Function newday()
	Print "\r\r"
	Print "===================================[ " + date() + " ]==================================="
	Print "\r\r\r"
End

//header:  prints seaparating "headline" message in History
Function header(msg)
	string msg
	print "\r\r"
	print "########################################################################"
	print "##\t\t\t" + msg
	print "########################################################################"
End

//div:  put big vertical space in history
Function div()
	Print "\r\r\r"
End

//msg:  Use this to make a message that's hard to miss in History
Function msg(msg)
	string msg
	Print "\r"
	Print "< ! > ##########[ " + msg + " ]########## < ! >";
	Print "\r"
End

//printError:  standard way to print error alerts to history (channels error recording)
Function printError(who, what)
	string who		//error was during this function name
	string what		//error explanation
	
	Print "#### ERROR during " + who + "():  " + what// + " ####"
	//Could customize this to also print in a notebook...
end

//####[ Graph Utilities ]###############################################

//graphPosition:  (Flexible) graph location and sizing convention for do1d, ...
//	Note: Sequentially fills left-to-right, then down, for num = 1,2,etc...
//	Could also use AutoPositionWindow in your code...
Function graphPosition(num)
	variable num	
	
	num = floor(num)//assume integer, starting with 1
	if((num < 1)||(num > 6))//error catch
		//AutoPositionWindow/M=0 //default?
		return 0	//soft abort
	endif
	
	num -= 1//rest of calculations use 0,1,2,3...
	
	variable height = 2.5	//graph height, inches
	variable width = 4.0	//graph width, inches
	variable hpad = 0.1	//horizontal padding
	variable vpad = 0.95		//vertical padding -- for some reason, still need this!
	variable numPerRow = 2	//Max number of graphs per row, before start new row beneath
	
	variable row = floor(num/numPerRow)
	variable col = floor(mod(num,numPerRow))
	
	movewindow/I (width+hpad)*col, (height+vpad)*row, (width+hpad)*col + width, (height+vpad)*row + height//left, top, right, bottom
	//movewindow/I 4.0*col, 2.5*row, 4.0*(col+1), 2.5*(row+1)
end

//graphAnnTopLeft: annotate graph at top left (typically for 1-line wave name)
Function graphAnnTopLeft(txt)
	string txt	//text content of graph annotation
	
	Textbox/c/n=topleft/f=0/a=LB/x=0/y=100/b=3 txt
end

//graphAnnTopRight: annotate graph at top right (typically for 1-line wavenote comments)
Function graphAnnTopRight(txt)
	string txt	//text content of graph annotation
	
	TextBox/C/N=topright/F=0/B=1/X=0.00/Y=0.00/E=2 "\JR\\f02\\Z08" + txt
end

//graphKillTop:  Kills top visible graph (without saving macro).
Function graphKillTop()
	string dummy = winname(0,1,1)//visible graphs only
		
	if(stringmatch(dummy,""))
		return 0//no graphs to work with
	else
		KillWindow $dummy
	endif
end

//graphKillAll:  Kills ALL visible graphs (even hidden and minimized graphs, without saving macro's).
//	Note: this is useful when you have accumulated way too many open graphs in a file, which you don't need anymore...
Function graphKillAll()
	//Make sure the user really wants to do this...
	DoAlert 1, "Are you sure you want to KILL ALL GRAPHS without saving any re-creation macro's?"
	if(V_flag != 1)
		return 0	//abort, b/c user did not click yes...
	endif
	
	string dummy = winname(0,1,1)//visible graphs only
		
	if(stringmatch(dummy,""))
		return 0//no graphs to work with
	endif
	
	do
		KillWindow $dummy
		dummy = winname(0,1,1)//visible graphs only
	while(!stringmatch("",dummy))
	//Loops until no visible graphs left to kill...
end

//graphHideAll:  Hides all visible graphs (hidden != minimized) without killing them.
Function graphHideAll()
	string dummy = winname(0,1,1)//visible graphs only
	
	if(stringmatch(dummy,""))
		return 0//no graphs to work with
	endif
	
	do
		SetWindow $dummy, hide=1
		dummy = winname(0,1,1)//visible graphs only
	while(!stringmatch("",dummy))
	//Loops until no visible graphs left to hide...
end

//graphUnhideAll:  Unhides ALL graphs (hidden != minimized).
Function graphUnhideAll()
	string dummy = winlist("*",";","WIN:1")//get a string list of all graphs
	
	variable ii
	
	for(ii = 0; ii < itemsinlist(dummy); ii += 1)
		SetWindow $stringfromlist(ii,dummy), hide=0
	endfor
end

//####[ Notebook Utilities ]############################################
//	Igor notebooks are useful for storing text, for example to create a log file to print later.
//	Paragraphs in a notebook file are nice for storing and retreaving text, which can be parsed  
//	with sscanf or stringbykey in functions later.

//nbAddParagraph:  Appends text to the end of a notebook as a paragraph (adds a carriage return)
Function nbAddParagraph(nb, msg)
	string nb		//name of notebook
	string msg		//text to add as a paragraph
	Notebook $nb, selection={endOfFile, endOfFile}	//put selection at end of file...
	Notebook $nb text=msg +"\r"	//use carriage return to make this a paragraph
end

//nbGetParagraph:  Returns a paragraph in a notebook
Function/S nbGetParagraph(nb, p)
	string nb		//name of notebook
	variable p		//paragraph number (notebooks start with p = 0)
	
	Notebook $nb selection={(p, 0), (p+1, 0)}	//move to current paragraph
	if (V_Flag != 0)	//no more lines in file? 
		printError("nbGetParagraph","Reached end of notebook "+nb+" for p="+num2istr(p)+"!")
		return ""		//error, return null string
	endif
	// select all characters in paragraph up to trailing CR 
	//Notebook $nb selection={startOfParagraph, endOfParagraph}
	GetSelection notebook, $nb, 2	//Get the selected text 
	return S_Selection	//S_Selection is set by GetSelection
end

//nbSetParagraph:  Replaces an existing paragraph in a notebook
Function nbSetParagraph(nb, p, txt)
	string nb		//name of notebook
	variable p		//paragraph number (notebooks start with p = 0)
	string txt		//text for paragraph, assume doesn't have carriage return already
	
	Notebook $nb selection={(p, 0), (p+1, 0)}	//move to current paragraph
	if (V_Flag != 0)	//no more lines in file? 
		printError("nbSetParagraph","Could't set because reached end of notebook "+nb+" for p="+num2istr(p)+"!")
	endif
	// select all characters in paragraph up to trailing CR 
	//Notebook $nb selection={startOfParagraph, endOfParagraph}
	Notebook $nb text=txt + "\r"
end

//nbNumParagraph:  Returns the number of paragraphs in a notebook (doesn't count empty final paragraph)
//NOTE:  I wish Igor had a better way to do this...  Mainly I want this function so looping
//over paragraphs in a notebook can be done with a for loop, not a do while.  
Function nbNumParagraph(nb)
	string nb		//name of notebook
	
	variable ii=0	//notebook paragraph index starts with 0
	do
		Notebook $nb selection={(ii, 0), (ii, 0)}	//move to current paragraph
		ii += 1	//now ii = # paragraphs checked...
	while(V_Flag == 0)//continue if selected location was valid...
	ii -= 1	//since last check was unsuccessful, decrement ii to now be number of valid paragraphs
	
	//Now check last paragraph, to see if it's empty, so can uncount it:
	Notebook $nb selection={(ii-1, 0), (ii, 0)}
	GetSelection notebook, $nb, 2	//Get the selected text
	if(stringmatch(S_Selection,""))
		ii -= 1	//don't count an empty last paragraph
	endif//this way, an extra carriage return in the notebook doesn't add to num of paragraphs
	//note that nbGetParagraph won't give an error for the last empty paragraph, though, so this isn't strictly necessary.
	
	Notebook $nb selection={endOfFile, endOfFile}//put loction at end of document, safe default behavior...
	
	return ii
end

