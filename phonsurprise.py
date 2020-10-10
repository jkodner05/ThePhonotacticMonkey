# encoding: utf-8

from themonkey import *

def calc_wordmetrics(wordfreqdict, charnlpdict):
    wordmetricdict = {}
    for word, freq in wordfreqdict.iteritems():
        numsylls = word.count("-") + 1
        word_nodash = word.replace("-","").replace(" ","").strip()
        numphones = len(word_nodash)
        phonsurprise = calc_phonsuprisal_by_len(word_nodash,numphones,charnlpdict)
        wordmetricdict[word] = (str(freq), str(numphones), str(numsylls), str(phonsurprise))
    return wordmetricdict

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Calculate Phonotactic Surprisal with Existing Language Model")

    parser.add_argument("wordfreqfile", help="word frequency file (eg output by bigguy.py)")
    parser.add_argument("psfile", help="char negative log probability file (*_ps.* files output by themonkey.py)")
    parser.add_argument("outputfile", help="output filename")

    args = parser.parse_args()

    wordfreqdict = {}
    with open(args.wordfreqfile, "r") as fin:
        next(fin)
        for line in fin:
            components = line.split(",")
            word = components[0]
            freq = components[1]
            wordfreqdict[word] = int(freq)
    
    charnlpdict = {}
    with open(args.psfile, "r") as fin:
        for line in fin:
            char, nlp = line.split(",")
            charnlpdict[char] = float(nlp)

    wordmetricdict = calc_wordmetrics(wordfreqdict, charnlpdict)
    with open(args.outputfile,"w") as f:
        f.write("word,wordfreq,numphones,numsylls,phonsuprise\n")
        for word, tup in wordmetricdict.iteritems():
            f.write("%s,%s\n"%(word,",".join(tup)))

    print "Phonontactic Surprisal has been calculated ( ﾟoﾟ)"
