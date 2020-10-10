# encoding: utf-8
import sys, os, os.path, re
import argparse


class Word(object):
    """A line in the chron file"""
    def __init__(self, index, form, x, y, ispolyseme):
        self.index = index
        self.form = form
        self.x = x
        self.y = y
        self.ispolyseme = ispolyseme


def read_chron(infname):
    """convert chron file to Word objects"""
    chronlist = []
    with open(infname,"r") as fin:
        next(fin)
        i = 0
        for line in fin:
            comps = line.split("\t")
            chronlist.append(Word(i, comps[3], comps[4], comps[5], comps[6].strip() == "True"))
            i += 1
    return chronlist


def read_Xpw(infname):
    """Read Xpw file and return freq sorted list of word forms"""
    tokenfreqs = None
    findword = re.compile(r"""\d+,[^\s'-]+?,(\d+),\d+,\d+,[^,]+,([^,]+)""")
    numtokens = 0
    tokenfreqs = {}
    wordlines = 0
    duplicates = 0
    rawformcounts = []
    with open(infname, "r") as f:
        for line in f:
            if not line:
                continue
            match = findword.match(line.replace('"','').replace("'",""))
            if not match:
                continue

            form = match.group(2).replace(" ","").strip()
            currcount = int(match.group(1))
            wordlines += 1
            rawformcounts.append((form, currcount))

    sortedforms = sorted(rawformcounts, key = lambda (k,v): (float(v),k), reverse=True)
    return sortedforms


def get_mapping(chronlist, Xpwfreqlist):
    """create a mapping between chron list forms and Xpw list forms"""
    def get_earlywords(chronlist, numuniqueforms):
        seen = {}
        for word in chronlist:
            if len(seen) == numuniqueforms:
                return seen
            if word.form not in seen:
                seen[word.form] = 0
            seen[word.form] += 1
            
    def get_graftdict(chron, Xpwpairs):
        assert len(chron) == len(Xpwpairs)
        mappings = {}
        for i, Xpwpair in enumerate(Xpwpairs):
            Xpwform = Xpwpair[0]
            mappings[chron[i][0]] = Xpwform
        return mappings

    chronfreqs = get_earlywords(chronlist, len(Xpwfreqlist))
    cutoff = sum(chronfreqs.values())
    sortedchronfreqs = sorted(chronfreqs.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)
    chrontoXpw = get_graftdict(sortedchronfreqs, Xpwfreqlist)
    return chrontoXpw, cutoff


def graft(chronlist, Xpwfreqlist):
    """graft the Xpw forms into the chron list"""
    mapping, cutoff = get_mapping(chronlist, Xpwfreqlist)
    print "RFuSF is everything before `year':", cutoff
    accountedfor = set([])
    for word in chronlist:
        if word.index < cutoff or word.ispolyseme:
            if word.form in mapping:
                newform = mapping[word.form]
                accountedfor.add(mapping[word.form])
                word.form = newform

    return chronlist


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Graft an Xpw-formatted frequently sorted wordlist into a PSM chronology file")

    parser.add_argument("inchronfile", help="input chron file")
    parser.add_argument("Xpwfile", help="input Xpw file")
    parser.add_argument("outchronfile", help="output grafted chron file")
    parser.add_argument("-l", "--length", help="number of words in output (|RF u SF u NF|)", type=int)
    
    args = parser.parse_args()

    chronlist = read_chron(args.inchronfile)
    Xpwfreqlist = read_Xpw(args.Xpwfile)
    chronlist = graft(chronlist, Xpwfreqlist)

    with open(args.outchronfile, "w") as f:
        f.write("year\tforms\tsenses\tnewform\tnewx\tnewy\tispolyseme\n")
        seen = set([])
        i = 0
        for word in chronlist:
            seen.add(word.form)
            if len(seen) > args.length:
                print i
                break
            i += 1
            f.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (word.index, len(seen), word.index+1, word.form, word.x, word.y, word.ispolyseme))
