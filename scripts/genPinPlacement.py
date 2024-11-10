#!/usr/bin/python3.12
import sys
import os
import re
from optparse import OptionParser
import pdb

#Example
# pinplacement -t <templateFile> -o <outputTclFile> --pgr <true/false>


parser = OptionParser()
parser.add_option("-t", "--templateFile", default="pin_placement.txt", dest="inFile", help="The template file where you have specified your pin placements [default: pin_placement.txt]")
parser.add_option("-o", "--outputFile", default="pin_placement.tcl", dest="outFile", help="The file name where the resulting tcl commands corrosponding to the input file are placed [default: pin_placement.tcl]")
parser.add_option("-r", "--pgr", default="False", dest="pgr", help="Set this to true if the pin placement is meant for a design with PGR")

#Stdcell height in microns
stdCellHeight=1.8
trackPitch = {"M2":0.2, "M3":0.2, "M4":0.2, "M5":0.2, "M6":0.2, "M7":0.2, "M8":0.8, "M9":0.8}
routeWidth= {"M2":0.1, "M3":0.1, "M4":0.1, "M5":0.1, "M6":0.1, "M7":0.1, "M8":0.4, "M9":0.4}
allowedTracks = [2,3,4,5,6,7] #Tracks 0, 1 and 8 are taken up by power rails.
trackOffset = {"M2":0, "M3":0.1, "M4":0, "M5":0.1, "M6":0, "M7":0.1, "M8":0, "M9":0.2}
faceDict = {"W":1, "N":2, "E":3, "S":4, "w":1, "n":2, "e":3, "s":4}
defaultMetalDict = {"W":"M2", "N":"M3", "E":"M2", "S":"M3"}

def readInputFile(inFile, pgr):
    pinList=[]
    mode=""
    defaultOffset=0.2
    pos=0    
    incr=0
    with open(inFile) as rfh:
        lines=rfh.readlines()
        for line in lines:
            line=line.strip()
            if re.search(r'^\s*$',line): ## or re.search(r'^//',line):
                continue
            ################3 Identify the type of mapping. Offset of direct-map ############
            elif re.search (r'^\s*type\s*=\s*(\w+)', line): #type=offset or #type=map
                m=re.search (r'^\s*type\s*=\s*(?P<mode>\w+)', line)
                mode=m.group('mode')
                if not( mode=='offset' or mode=='map'):
                    print("Invalid mode. Mode must be either offset or map. {0} selected. Please specify a valid mode".format(mode))
                ###################### Identify the default Offset #############################
                # elif re.search (r'\s*defaultOffset', line): #default_offset=245.52
            elif re.search (r'\s*defaultOffset\s*=\s*[0-9.]+', line): #default_offset=245.52
                m=re.search (r'\s*defaultOffset\s*=\s*(?P<offset>[0-9.]+)', line)
                defaultOffset=float(m.group('offset'))
                ###################### Identify new "signpost" #############################
            elif re.search(r'^#[ENWSenws],\s*[0-9.]*',line): #You have a marker #E, #W, #N, #S
                line=re.sub(r'^#','',line)
                line=re.split(',',line)
                side=faceDict[line[0]]
                currentPos=float(line[1]) if len(line)>1 else 0
                ###################### Pin statement #############################
            else: #Regular pin assignment nnnn
                signal = "INVALID"
                line=re.sub(r'\s+', '',line)
                lineList=line.split(r',') #Break on a comma
                #######Get the metal layer and the offset for the line###########
                m=re.search(r'layer\s*=\s*(?P<metalLayer>M[0-9]+)',lineList[1])
                metalLayer=m.group('metalLayer')
                m=re.search(r'\+(?P<offset>[0-9.]+)',lineList[-1])
                offset = float(m.group('offset')) if m else defaultOffset
                #Look for offset
                ################# Is there a bus statement ###################
                if(re.search(r'[\<\[]',lineList[0])):  #Check if signal is a bus
                    if(re.search(r':',lineList[0])):   #If bus, is it a range
                        m=re.search(r'(?P<prefix>.*?)[\<\[]\s*(?P<max>[0-9]+):(?P<min>[0-9]+)\s*[\<\]]',lineList[0])
                        prefix,left,right =m.group('prefix'), int(m.group('max')), int(m.group('min'))
                        # (stop,start)=(right,left) if left>right else (left,right)
                        incr = 1 if right>left else -1
                        ##Get the pitch for the bus
                        m=re.search(r'pitch\s*=\s*(?P<pitch>[0-9.]+)',line)
                        pitch=float(m.group('pitch'))
                        # stop= m if m>n else n
                        ################# Is there a  ###################
                    else:
                        m=re.search(r'(?P<prefix>.*?)[\<\[]\s*(?P<val>[0-9]+)\s*[\]\]]',lineList[0])
                        prefix,m =m.group('prefix'), int(m.group('val'))
                        left=m
                        right= m
                    for i in range(left,right+incr,incr):
                        last=1 if i==right else 0
                        signal=prefix + "[" + str(i) + "]"
                        if(pgr in ['t', 'T', 'true', 'True', '1', 'y', 'Y', 'yes', 'Yes']):
                            currentPos,pinInfoList=unpackLinePGR(lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side)
                        else:
                            currentPos,pinInfoList=unpackLineNoPGR(lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side)
                        pinList.append(pinInfoList)
                else:
                    if(pgr in ['t', 'T', 'true', 'True', '1', 'y', 'Y', 'yes', 'Yes']):
                        currentPos,pinInfoList=unpackLinePGR(lineList,lineList[0],metalLayer,0,1,mode,currentPos,offset,side)
                    elif(pgr in ['f', 'F', 'false', 'False', '0', 'n', 'N', 'no', 'No']):
                        currentPos,pinInfoList=unpackLineNoPGR(lineList,lineList[0],metalLayer,0,1,mode,currentPos,offset,side)
                    else:
                        print("Invalid value for pgr. Pgr must be true or false. {0} selected. Please specify a valid value".format(pgr))
                    pinList.append(pinInfoList)

    return pinList
                            

def unpackLinePGR (lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side):
    signalList=[]
    nextPos="invalid"
    if mode=='offset':
        nextPos= float(currentPos)+ offset if(pitch==0 or last==1) else float(currentPos)+ pitch            
    else:
        currentPos = float(lineList[-1])
    signalList.extend((signal,metalLayer,currentPos,side))
    return nextPos,signalList

def unpackLineNoPGR (lineList,signal,metalLayer,pitch,last,mode,currentPos,offset,side):
    signalList=[]
    nextPos="invalid"
    if mode=='offset':
        if(pitch==0 or last==1):
            nextPos=findLegalPinLoc(float(currentPos)+offset,trackPitch[metalLayer],trackOffset[metalLayer],routeWidth[metalLayer], side)
        else:
            nextPos=findLegalPinLoc(float(currentPos)+pitch,trackPitch[metalLayer],trackOffset[metalLayer],routeWidth[metalLayer], side)
    else:
        currentPos = findLegalPinLoc(float(lineList[-1]),trackPitch[metalLayer],trackOffset[metalLayer],routeWidth[metalLayer], side)
    signalList.extend((signal,metalLayer,currentPos,side))
    return nextPos,signalList

#Find the nearest legal "on-track" location that is greater than the existing location
def findLegalPinLoc(loc, trackPitch, trackOffset, routeWidth, side):
    # print(f"stdCellHeight:{stdCellHeight}")
    trackIndex=((loc-trackOffset) % stdCellHeight) / trackPitch
    # if(trackIndex== 0 or trackIndex == 1 or trackIndex==8): print("illegal pin location")
    stdCellCount=int((loc-trackOffset)/stdCellHeight)
    found=0
    legalIndex=allowedTracks[0]
    for index in allowedTracks:
        if(index>=trackIndex):
            legalIndex = index
            found=1
            break
    if(found==0): #Pick next track over. Legal index defaults to iallowedTracks[0]
        stdCellCount+=1

    # Snap final location to track based on side.
    if side in [1,3]:
        finLoc = trackOffset+stdCellCount*stdCellHeight+trackPitch*legalIndex; # - routeWidth*0.5
    elif side in [2,4]:
        finLoc = trackOffset+stdCellCount*stdCellHeight+trackPitch*legalIndex
    else:
        raise ValueError("Side can only be 1,2,3,4!")

    finLoc = round(finLoc,2)
    print(f"Side = {side}. Init loc was {loc}. Final loc was {finLoc}.")
    return finLoc 

(options,args) = parser.parse_args()
wfh=open(options.outFile,'w')
pinList=readInputFile(options.inFile, options.pgr)
for pin in pinList:
    wfh.write("create_pin_constraint -type individual -ports {%s} -layers {%s} -width 0.1 -length 0.1 -sides %s -offset %.2f\n" %(pin[0],pin[1],pin[3],pin[2]))
wfh.close()
    # print pinList