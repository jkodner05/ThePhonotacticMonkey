#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, math, os, subprocess, glob, re
reload(sys)
import argparse
sys.setdefaultencoding('utf-8')
import unicodedata
from unicodedata import normalize

oedOldDict = dict()
oedNewDict = dict()
newFormsOnly = dict()
oldFormsNewMeaningOnly = dict()
staleFormsOnly = dict()

NFphonDict = dict()
RFphonDict = dict()
SFphonDict = dict()

##
## Main method block
##
if __name__=="__main__":
    parser = argparse.ArgumentParser(description = "Intersect extracted OED extries with CELEX")


    parser.add_argument("oedOldSource", help="Source to OED OF entries") # OEDold.txt
    parser.add_argument("oedNewSource", help="Source to OED NF entries") # OEDnew.txt
    parser.add_argument("celexSource", help="Source to CELEX lemma file (English)") # epl.csv
    parser.add_argument("newFormsFileSource", help="Source to OED NF entries") # epl_onlyOEDnewForms.csv
    parser.add_argument("oldFormsNewMeaningFileSource", help="Source to OED RF entries") # epl_onlyOEDoldFormsNewMeaning.csv
    parser.add_argument("oldStaleFormsFileSource", help="Source to OED SF entries") # epl_onlyOEDoldStaleForms.csv
    parser.add_argument("oldFormsAllFileSource", help="Source to OED RF+SF entries") # epl_onlyOEDAlloldForms-RFSF.csv

    args = parser.parse_args()


    # read oed words into dict
    with open(args.oedOldSource, 'r') as oedOldInputFile:
        for currLine in oedOldInputFile:
            currLineTokens = currLine.lstrip().split(' ')
            #print currLineTokens
            if len(currLineTokens) > 1:
                currNumSenses = currLineTokens[0]
                currWord = currLineTokens[1].lower().rstrip()
            #    print currWord
                if currWord not in oedOldDict:
                    oedOldDict[currWord] = currNumSenses
        oedOldInputFile.close()

    
    with open(args.oedNewSource, 'r') as oedNewInputFile:
        for currLine in oedNewInputFile:
            currLineTokens = currLine.lstrip().split(' ')
            #print currLineTokens
            if len(currLineTokens) > 1:
                currNumSenses = currLineTokens[0]
                currWord = currLineTokens[1].lower().rstrip()
            #    print currWord
                if currWord not in oedNewDict:
                    oedNewDict[currWord] = currNumSenses
        oedNewInputFile.close()


    # Check (non)-intersection of new and old.
    for currForm in oedNewDict:
        if currForm not in oedOldDict:
            newFormsOnly[currForm] = 1
        else:
            oldFormsNewMeaningOnly[currForm] = 1

    # Get stale forms (in old but not in new)
    for currForm in oedOldDict:
        if currForm not in oedNewDict:
            staleFormsOnly[currForm] = 1

    # Sanity check on dict lengths
    print 'Pre-1900 Forms:', len(oedOldDict.keys())
    print 'Post-1900 Forms:', len(oedNewDict.keys()) 
    print 'NF Forms total:', len(newFormsOnly.keys())
    print 'RF Forms total:', len(oldFormsNewMeaningOnly.keys())
    print 'SF Forms total:', len(staleFormsOnly.keys())


    ## iterate over CELEX
    ## For each line, check if word in each oed-dict
    ## If so then keep it, save to output, otherwise skip
    printedFirstLine = False
    newFormsAlsoInCelex = 0
    oldFormsNewMeaningsAlsoInCelex = 0
    staleFormsAlsoInCelex = 0
    with open(args.celexSource, 'r') as celexInputFile:
        with open(args.newFormsFileSource, 'w') as newFormsFile:
            with open(args.oldFormsNewMeaningFileSource, 'w') as oldFormsNewMeaningFile:    
                with open(args.oldFormsAllFileSource, 'w') as oldFormsAllFile:
                    with open(args.oldStaleFormsFileSource, 'w') as oldStaleFormsFile:
                        for currLine in celexInputFile:
                            cleanedCurrLine = currLine.rstrip()
                            currLineTokens = currLine.split(',')
                            if len(currLineTokens) > 1:
                                if not printedFirstLine:
                                    newFormsFile.write(cleanedCurrLine+'\n')
                                    oldFormsNewMeaningFile.write(cleanedCurrLine+'\n')
                                    oldFormsAllFile.write(cleanedCurrLine+'\n')
                                    oldStaleFormsFile.write(cleanedCurrLine+'\n')
                                    printedFirstLine = True
                                else:
                                    IdNum = currLineTokens[0]
                                    Head = currLineTokens[1].lower()
                                    currPhon = currLineTokens[5]
                                    if Head in newFormsOnly:
                                        NFphonDict[currPhon] = cleanedCurrLine
                                    if Head in oldFormsNewMeaningOnly:
                                        RFphonDict[currPhon] = cleanedCurrLine
                                    if Head in staleFormsOnly:
                                        SFphonDict[currPhon] = cleanedCurrLine
                        oldStaleFormsFile.flush()
                        oldStaleFormsFile.close()
                    oldFormsAllFile.flush()
                    oldFormsAllFile.close()
                oldFormsNewMeaningFile.flush()
                oldFormsNewMeaningFile.close()
            newFormsFile.flush()
            newFormsFile.close()
        celexInputFile.close()

    # loop through all sets and check for repeat entries (which should be treated as RFs)
    with open(args.newFormsFileSource, 'a') as newFormsFile:
        for phonForm, fullLine in NFphonDict.items():
            if phonForm in SFphonDict.keys():
                # add to RF
                if phonForm not in RFphonDict.keys():
                    RFphonDict[phonForm] = fullLine
                del SFphonDict[phonForm]
                continue
            if phonForm in RFphonDict.keys():
                continue
            newFormsFile.write(fullLine+'\n')
            newFormsAlsoInCelex += 1
        newFormsFile.flush()
        newFormsFile.close()

    with open(args.oldFormsAllFileSource, 'a') as oldFormsAllFile:
        with open(args.oldStaleFormsFileSource, 'a') as oldStaleFormsFile:
            for phonForm, fullLine in SFphonDict.items():
                if phonForm in RFphonDict.keys():
                    continue
                oldStaleFormsFile.write(fullLine+'\n')
                staleFormsAlsoInCelex += 1
                oldFormsAllFile.write(fullLine+'\n')
            oldStaleFormsFile.flush()
            oldStaleFormsFile.close()

        with open(args.oldFormsNewMeaningFileSource, 'a') as oldFormsNewMeaningFile: 
            for phonForm, fullLine in RFphonDict.items():
                oldFormsNewMeaningFile.write(fullLine+'\n')
                oldFormsNewMeaningsAlsoInCelex += 1
                oldFormsAllFile.write(fullLine+'\n')
            oldFormsNewMeaningFile.flush()
            oldFormsNewMeaningFile.close()
        oldFormsAllFile.flush()
        oldFormsAllFile.close()
    

    # Check intersection sizes
    print 'newFormsAlsoInCelex: ' + str(newFormsAlsoInCelex)
    print 'oldFormsNewMeaningsAlsoInCelex: ' + str(oldFormsNewMeaningsAlsoInCelex)
    print 'oldStaleFormsAlsoInCelex: ' + str(staleFormsAlsoInCelex)