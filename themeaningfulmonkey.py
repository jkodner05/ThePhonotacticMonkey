# encoding: utf-8
import time

import Queue
import sys, os, os.path
import argparse
import re
from collections import defaultdict
from math import log, sqrt
import random

START = "%"
STOP = "!"

CELEXSAMPA = "CELEXSAMPA"

SYLL = "SYLL"

ADDONE = "ADDONE"
NONE = "NONE"
DEFAULT_SMOOTHING = ADDONE

CORPUSTYPE = "default"
SMOOTHINGTYPE = DEFAULT_SMOOTHING
NATURAL = False
WORDNET = False

LG_FUNC = lambda x: log(x,2)
LOG_FUNC = LG_FUNC

CELEXSAMPA_VOWELS = set(["I","E","{","Q","V","U","$","3","i","1","6","u","2","4","6","7","8","#","$","9","@",":","~","5","c","q","0","C","F","H","P","R"]) 
DIPHTHVOWELS = set([":","~"])


def prob_to_type(rangedicts,rando, context=None):
    if context == None:
        rangedict = rangedicts
    else:
        rangedict = rangedicts[context]
    for typerange, type in rangedict.iteritems():
        if typerange[0] <= rando and rando < typerange[1]:
            return type
    raise Exception("Problem with rando parameter")
    return


def syllable_has_one_head(word):
    sylls = word.split("-")
    for syll in sylls:
        numheads = 0
        for char in syll:
            if char in CELEXSAMPA_VOWELS:
                numheads += 1
        if numheads != 1:
            return False
    return True


def calc_syll_phonfreqs(syllfreqs,syllcharfreqs,syllcondcharfreqs):
    numtokens = 0
    startpadding = START + START
    for syll, freq in syllfreqs.iteritems():
        numtokens += freq
        paddedsyll = startpadding + syll + STOP
        syllcharfreqs, syllcondcharfreqs = update_counts_dicts(syllcharfreqs, syllcondcharfreqs, paddedsyll, freq)
    return numtokens

def calc_syll_charprobs(syllfreqs):
    syllcharfreqs = defaultdict(int)
    syllcondcharfreqs = defaultdict(lambda: defaultdict(int))
    numtokens = 0
    numtokens = calc_syll_phonfreqs(syllfreqs,syllcharfreqs,syllcondcharfreqs)
    syllprobs, syllcontextprobs = calc_probs(syllcharfreqs,syllcondcharfreqs)
    return syllprobs, syllcontextprobs


def calc_word_neglogprobs(freqdict):
    totalcount = sum(freqdict.values())
    neglogprobdict = defaultdict(float)
    probsum = 0
    for word, freq in freqdict.iteritems():
        probsum += float(freq)/totalcount
        currneglogprob = -(LOG_FUNC(freq)-LOG_FUNC(totalcount))
        neglogprobdict[word] = currneglogprob
    return neglogprobdict

def calc_neglognphoneprob(nphoneprobdict,contextprobdict):
    neglogprobdict = {}
    for char, contexts in nphoneprobdict.iteritems():
        if not contextprobdict:
            neglogprobdict[char] = -LOG_FUNC(contexts)
        else:
            for context, contextprob in contexts.iteritems():
               nphone = context+char
               neglogprob = -(LOG_FUNC(nphoneprobdict[char][context])-LOG_FUNC(contextprobdict[context]))
               neglogprobdict[nphone] = neglogprob
    return neglogprobdict


def calc_phonsuprisal_by_len(word, numphones, neglogprobdict):
    currphonsurprise = 0

    paddedword = word
    numphones += 1 # properly normalize by the number of triphones
    cut = 2
    paddedword = START + START + word + STOP
    for i in range(len(paddedword))[cut:]:
        currtriphone = paddedword[i-cut:i+1]
        if currtriphone in neglogprobdict:
            triphoneneglogprob = neglogprobdict[currtriphone]
            currphonsurprise += triphoneneglogprob

    phonsurprisebylen = currphonsurprise/numphones

    return phonsurprisebylen


def recalc_without_dashes(wordfreqdict):
    charfreqs_nodash = defaultdict(int)
    condcharfreqs_nodash = defaultdict(lambda : defaultdict(int))
    wordfreqdict_nodash = defaultdict(int)
    for word, freq in wordfreqdict.iteritems():
        preppedword = START + START + word.replace("-","") + STOP
        wordfreqdict_nodash[preppedword] += freq
    for word, freq in wordfreqdict_nodash.iteritems():
        charfreqs_nodash, condcharfreqs_nodash = update_counts_dicts(charfreqs_nodash, condcharfreqs_nodash, word, freq)

    normalize_counts(charfreqs_nodash,condcharfreqs_nodash)
    charprobs_nodash, condcharprobs_nodash = calc_probs(charfreqs_nodash, condcharfreqs_nodash)
    return charfreqs_nodash, condcharfreqs_nodash, charprobs_nodash, condcharprobs_nodash


def gen_metrics(wordfreqdict, wordsensedict, charprobdict, contextprobdict, wordstosylls=None):
    charfreqdict_nodash, contextfreqdict_nodash, charprobdict_nodash, contextprobdict_nodash = recalc_without_dashes(wordfreqdict)
    wordmeasuredict = defaultdict(tuple)
    if len(wordfreqdict.keys()) != len(wordfreqdict.keys()):
        raise Exception("The word frequency dictionary (len: %s) is not the same length as the word sense dictionary (len: %s)" % (len(wordfreqdict.keys()),len(wordsensedict.keys())))
    wordfreq_neglogprobdict = calc_word_neglogprobs(wordfreqdict)
    wordsense_neglogprobdict = calc_word_neglogprobs(wordsensedict)
    charprobdict_nodash, contextprobdict_nodash = calc_probs(charfreqdict_nodash, contextfreqdict_nodash)
    char_neglogprobdict_nodash = calc_neglognphoneprob(charprobdict_nodash, contextprobdict_nodash)

    for word, freq in wordfreqdict.iteritems():
        if word not in wordsensedict:
            raise Exception("%s is not in the word sense dictionary" % word)
        numsylls = word.count("-") + 1
        if wordstosylls:
            numsylls = len(wordstosylls[word])
        numsenses = wordsensedict[word]

        word_nodash = word.replace("-","").replace(" ","").strip()
        numphones = len(word_nodash)

        wordfreq_neglogprob = wordfreq_neglogprobdict[word]
        wordsense_neglogprob = wordsense_neglogprobdict[word]

        phonsurprise = calc_phonsuprisal_by_len(word_nodash,numphones,char_neglogprobdict_nodash)

        wordmeasuredict[word] = (str(freq),str(wordfreq_neglogprob),str(numsenses),str(wordsense_neglogprob),str(numphones),str(numsylls),str(phonsurprise))
    return wordmeasuredict, char_neglogprobdict_nodash



def gen_syll_metrics(wordfreqdict, wordsensedict, charprobdict, wordstosylls=None):
    syllmeasuredict = defaultdict(tuple)
    syllfreqs = defaultdict(int)
    wordspersyll = defaultdict(int)

    #get syll frequencies and numwords appearing in
    for word, freq in wordfreqdict.iteritems():
        numsylls = word.count("-") + 1
        sylls = word.split("-")
        if wordstosylls:
            sylls = wordstosylls[word]
            numsylls = len(sylls)
        for syll in word.split("-"):
            syllfreqs[syll] += freq
            wordspersyll[syll] += wordsensedict[word]

    syllfreq_neglogprobdict = calc_word_neglogprobs(syllfreqs)
    syllcharprobdict, syllcondcharprobdict = calc_syll_charprobs(syllfreqs)
    triphone_neglogprobdict = calc_neglognphoneprob(syllcharprobdict, syllcondcharprobdict)
    for syll in syllfreqs:
        numphones = len(syll)
        numwords = wordspersyll[syll]
        syllfreq_neglogprob = syllfreq_neglogprobdict[syll]
        phonsurprise = calc_phonsuprisal_by_len(syll,numphones,triphone_neglogprobdict)
        syllmeasuredict[syll] = (str(syllfreqs[syll]),str(wordspersyll[syll]),str(numphones),str(syllfreq_neglogprob),str(phonsurprise))
    return syllmeasuredict



def calc_char_probs_from_condfreqs(freqs, condfreqs, calclist=None):
    condprobs = defaultdict(lambda : defaultdict(float))
    if not calclist:
        for char, contexts in condfreqs.iteritems():
            for context, contextcount in contexts.iteritems():
                contextcharcount = contexts[context] # This is #BA where B is a bigram
                condprobs[char][context] = float(contextcharcount) / sum(freqs.values())
    else:
        cutmax = 2
        for triphone in calclist:
            char = triphone[cutmax]
            context = triphone[0:cutmax]
            contextcharcount = condfreqs[char][context] # This is #BA where B is a bigram
            condprobs[char][context] = float(contextcharcount) / sum(freqs.values())
            
    return condprobs


def calc_context_probs(condfreqs, calclist=None):
    contextfreqs = defaultdict(int)
    contextprobs = defaultdict(float)
    for char, contexts in condfreqs.iteritems():
        for context, contextfreq in contexts.iteritems():
            contextfreqs[context] += contextfreq
    totalcontextcount = float(sum(contextfreqs.values()))
    if calclist:
        cutmax = 2
        for triphone in calclist:
            context = triphone[0:cutmax]
            contextfreq = contextfreqs[context]
            contextprobs[context] = contextfreq / totalcontextcount
    else:
        for context, contextfreq in contextfreqs.iteritems():
            contextprobs[context] = contextfreq / totalcontextcount
    return contextprobs


def calc_probs(freqs, condfreqs, calclist=None):
    count = sum(freqs.values())
    probs = calc_char_probs_from_condfreqs(freqs, condfreqs, calclist)
    contextprobs = calc_context_probs(condfreqs, calclist)
    return probs, contextprobs


def update_counts_dicts(charfreqs, condcharfreqs, word, valueToAdd):
    for i, char in enumerate(word):
        if i > 1:
            charfreqs[char] += valueToAdd          
            condcharfreqs[char][word[i-2:i]] += valueToAdd
    return charfreqs, condcharfreqs


def read_celex_Xpw(filename, charfreqs, condcharfreqs, withdashes):
    findword = re.compile(r"""\d+,[^\s'-]+,(\d+),[^,]+,\d+,[^,]+,([^,]+)""")
    #Column format: IdNum,Word,IdNumLemma,Cob,... We want Word and Cob (raw frequency)
    numtokens = 0
    with open(filename, "r") as f:
        for line in f:
            if not line:
                continue
            if withdashes:
                match = findword.match(line.replace('"','').replace("'",""))
            else:
                match = findword.match(line.replace('"','').replace("'","").replace("-",""))
            if not match:
                continue
            word = START + START + match.group(2).replace(" ","").strip() + STOP
            currcount = int(match.group(1))
            if currcount == 0: #if the word has a 0 count in the corpus, we're skipping it 
                currcount = 1 #addone
            numtokens += currcount
            typecount = 1
            charfreqs, condcharfreqs = update_counts_dicts(charfreqs, condcharfreqs, word, typecount)
    return numtokens



def normalize_counts(freqs, condfreqs):
    for char,contexts in condfreqs.iteritems():
        for contextc in freqs.keys():        #iterate of freqs.keys() because that's guaranteed to contain all the characters    
            for contextb in freqs.keys():
                if contextc != START and contextb == START: #don't add char START context
                    continue
                context = contextc+contextb
                if context not in contexts:
                    contexts[context] += len(context)
                    for char in context: 
                        freqs[char] += 1
    return


def traverse_corpus_dir(dirname, withdashes=False):
    freqs = defaultdict(int)
    condfreqs = defaultdict(lambda : defaultdict(int))
    tokenfreqs = None
    typelemmas = None
    wcount = read_celex_Xpw(dirname, freqs, condfreqs, withdashes)

    normalize_counts(freqs,condfreqs)
    return freqs, condfreqs, tokenfreqs, typelemmas

def gen_forms(charprobs, contextprobs, numforms):
    fcount = 0
    newformqueue = Queue.Queue()
    rangedicts = defaultdict(lambda : defaultdict(float))
    contextlowerbounds = defaultdict(float)
    scalingfactors = defaultdict(float)

    for context, contextprob in contextprobs.iteritems():
        scalingfactors[context] = 1/contextprob

    #create ranges
    for char, probs in charprobs.iteritems():
        for context, condprob in probs.iteritems():
            currscalingfactor = scalingfactors[context]
            scaledcondprob = condprob*currscalingfactor
            currlowerbound = contextlowerbounds[context]
            (rangedicts[context])[(currlowerbound, currlowerbound + scaledcondprob)] = char
            contextlowerbounds[context] += scaledcondprob
    
    #generate vocabulary
    numinvalidsyllforms = 0
    while fcount < numforms:
        newform = []
        nextchar = START
        prevcontext = START + START
        while nextchar == START:
            nextchar = prob_to_type(rangedicts,random.random(),prevcontext)
        
        while nextchar != STOP:
            newform.append(nextchar)
            prevcontext = prevcontext[-1] + nextchar
            nextchar = START
            while nextchar == START:
                nextchar = prob_to_type(rangedicts,random.random(),prevcontext)
        newformstring = "".join(newform)


        if len(newformstring) == 0 or newformstring[0] == "-" or newformstring[-1] == "-" or "--" in newformstring: #don't want forms beginning or ending with syllable breaks. Don't want two breaks in a row. (CELEXSAMPA)
            continue
        if not syllable_has_one_head(newformstring):
            numinvalidsyllforms += 1
            continue

        fcount += 1
        newformqueue.put_nowait(newformstring)
    return newformqueue



def gen_psm_lexicon(charprobs, contextprobs, numwords, numsenses, newformqueue, sameness_threshold):
    def euclidian(sense1, sense2):
        return sqrt((sense1[0]-sense2[0])**2+(sense1[1]-sense2[1])**2)

    def find_nearest(newsense, senses):
        nearest = None
        mindist = 100
        for sense in senses:
            distance = euclidian(newsense, sense)
            if distance < mindist and distance < sameness_threshold:
                nearest = sense
                mindist = distance
        return nearest

    def find_nearby(newsense, sortedsenses, sortedabsdistances):
        #binary search then count left and right within sameness_threshold
        nearbysenses = []
        if not sortedsenses:
            return nearbysenses, 0
        absolutedistance = euclidian(newsense, (0,0))
        left = 0
        right = len(sortedsenses)-1
        i = int((left+right)/2)            
        while left <= right:
            if sortedabsdistances[i] < absolutedistance:
                left = i+1
            else:
                right = i-1
            i = int((left+right)/2)            
        #the lowest value corresponds to i == -1, which causes problems in python
        i = max(i, 0)

        if abs(sortedabsdistances[i] - absolutedistance) < sameness_threshold:
            nearbysenses.append(sortedsenses[i])
        lefti = max(0, i-1)
        while lefti > 0 and abs(sortedabsdistances[lefti] - absolutedistance) < sameness_threshold:
            nearbysenses.append(sortedsenses[lefti])
            lefti -= 1
        righti = min(len(sortedabsdistances)-1, i+1)
        while righti < len(sortedsenses) and abs(sortedabsdistances[righti] - absolutedistance) < sameness_threshold:
            nearbysenses.append(sortedsenses[righti])
            righti += 1
        return nearbysenses, i
        
    def insert_sense(sortedsenses, sortedabsdistances, newsense, newi):
        absolutedistance = euclidian(newsense, (0,0))
        if not sortedsenses:
            return [newsense], [absolutedistance]
        if sortedabsdistances[newi] < absolutedistance:
            sortedsenses.insert(newi+1, newsense)
            sortedabsdistances.insert(newi+1, absolutedistance)
        else:
            sortedsenses.insert(newi, newsense)
            sortedabsdistances.insert(newi, absolutedistance)
        return sortedsenses, sortedabsdistances


    formsensedict = defaultdict(set)
    formfreqdict = defaultdict(int)
    homophonedict = defaultdict(int)
    chronology = []

    sortedsenses = []
    sortedabsolutedistances = []
    senseformdict = {}
    numnewforms = 0
    start = time.time()
    instart = time.time()
    for i in range(0, numsenses):
        newsense = (random.random()*100,random.random()*100)

        nearbysenses, newi = find_nearby(newsense, sortedsenses, sortedabsolutedistances)

        nearestsense = find_nearest(newsense, nearbysenses)
        sortedsenses, sortedabsolutedistances = insert_sense(sortedsenses, sortedabsolutedistances, newsense, newi)

        if not i % 500:
            print(i, numnewforms, newsense, len(nearbysenses), time.time()-instart)
            instart = time.time()
        newform = None
        ispolyseme = False
        if nearestsense:
            newform = senseformdict[nearestsense]
            ispolyseme = True
        else:
            newform = newformqueue.get_nowait()
            numnewforms += 1
            homophonedict[newform] += 1
        senseformdict[newsense] = newform
        formsensedict[newform].add(newsense)
        formfreqdict[newform] += 1
        chronology.append((len(formsensedict.keys()),len(senseformdict.keys()), newform, newsense, ispolyseme))
    print(time.time() - start)


    return dict(formsensedict), dict(formfreqdict), chronology, dict(homophonedict)






if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Phonotactic-Semantic Monkey Lexicon Generation")

    parser.add_argument("inputdir", help="directory containing corpus")
    parser.add_argument("outputfile", help="output filename; if omitted, will print debug files instead")
    parser.add_argument("numforms", help="number of forms to generate", type=int)
    parser.add_argument("numsenses", help="number of senses to distribute", type=int)
    parser.add_argument("-s", "--seed", help="fix random seed", type=str)
    parser.add_argument("-t", "--threshold", help="polysemy threshold", type=float)
    
    args = parser.parse_args()

    if args.numsenses < args.numforms:
        raise Exception("Number of senses cannot be less than number of word forms")

    if args.seed != None:
        random.seed(args.seed)


    CORPUSTYPE = CELEXSAMPA
    language = "English"

    #get subunit probabilities 
    dashedwords = set()
    freqs, contextfreqs, formfreqdict, formsensedict = traverse_corpus_dir(args.inputdir, withdashes=True)

    probs, contextprobs = calc_probs(freqs, contextfreqs)
    print "Generating PSM-lexicon of sense count %s" % args.numsenses
    newformqueue = gen_forms(probs, contextprobs, args.numforms)

    formsensedict, formfreqdict, chronology, homophonedict = gen_psm_lexicon(probs, contextprobs, args.numforms, args.numsenses, newformqueue, sameness_threshold=args.threshold)

    sortedforms = sorted(formfreqdict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]
    sortedhomophones = sorted(homophonedict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]
    sortedsenses = sorted(formsensedict.iteritems(), key = lambda (k,v): (float(len(v)),k), reverse=True)#[0:100]

    #write chronology file
    with open(args.outputfile.replace(".csv","_chron.txt"), "w") as f:
        f.write("year\tforms\tsenses\tnewform\tnewx\tnewy\tispolyseme\n")
        year = 0
        for forms, senses, newform, newsense, ispolyseme in chronology:
            f.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (year, forms, senses, newform, newsense[0], newsense[1], ispolyseme))
            year += 1
            
    #do gemmatria 
    # CSV format:
    # word,  
    # raw word freq,   
    # word negative natural log probility,   
    # raw num word senses,   
    # word senses negative natural log probility,
    # num phones
    # num syllables
    # phonotactic surprisal divided by word length (avg phonsurprise per phone)
    syllabifications = None
    print "Calculating metrics"
    formsensedict_flat = {form:len(senses) for form, senses in formsensedict.items()}
    wordmetricdict, charneglogprobdict = gen_metrics(formfreqdict, formsensedict_flat, probs, contextprobs, syllabifications)
    with open(args.outputfile,"w") as f:
        f.write("word,wordfreq,wordneglogprob,numwordsenses,wordsensesneglogprob,numphones,numsylls,phonsuprise\n")
        for word, tup in wordmetricdict.iteritems():
            f.write("%s,%s\n"%(word,",".join(tup)))
    sortedcharneglogprobs = sorted(charneglogprobdict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]
    with open(os.path.splitext(args.outputfile)[0] + "_ps" + os.path.splitext(args.outputfile)[1],"w") as f:
        for char, neglogprob in sortedcharneglogprobs:
            f.write("%s,%s\n"%(char,neglogprob))

    # CSV format:
    # syllable,
    # syllable token frequency
    # number of words syllable appears in
    # number of phones in syllables
    # syllable negative log probability
    # syllable phonotactic surprisal divided by syllable length
    syllmetricdict = gen_syll_metrics(formfreqdict, formsensedict_flat, probs, syllabifications)
    with open(args.outputfile.replace(".csv","_sylls.csv"),"w") as f:
        f.write("syll,syllfreq,wordspersyll,numphones,syllneglogprob,phonsurprise\n")
        for syll, tup in syllmetricdict.iteritems():
            f.write("%s,%s\n"%(syll,",".join(tup)))

    print "This %s historic monkey is done @(･o･)@ @(･o･)@ @(･o･)@" % (language)

