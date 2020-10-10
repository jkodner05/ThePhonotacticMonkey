#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, math, os, subprocess, glob, re
reload(sys)
import argparse
sys.setdefaultencoding('utf-8')
import unicodedata
from unicodedata import normalize


##
## Main method block
##
if __name__=="__main__":
    parser = argparse.ArgumentParser(description = "Intersect extracted OED extries with CELEX")


    parser.add_argument("input_Xpl", help="Source to OED OF entries")
    parser.add_argument("output_Xpw", help="Source to OED NF entries")

    args = parser.parse_args()


    # read oed words into dict
    with open(args.input_Xpl, 'r') as input_Xpl_File:
        with open(args.output_Xpw, 'w') as output_Xpw_File:
            readFirstLine = False
            for currLine in input_Xpl_File:
                currLineTokens = currLine.lstrip().split(',')
                if not readFirstLine:
                    output_Xpw_File.write("IdNum,Word,Cob,IdNumLemma,PronCnt,PronStatus,PhonStrsDISC,PhonCVBr,PhonSylBCLX\n")
                    readFirstLine = True
                else:
                    currLineTokens.insert(3, "0")
                    currLineUpdated = ",".join(currLineTokens)
                    output_Xpw_File.write(currLineUpdated)
            input_Xpl_File.flush()
            input_Xpl_File.close()
        input_Xpl_File.close()

    print 'Finished converting from Xpl to Xpw format'