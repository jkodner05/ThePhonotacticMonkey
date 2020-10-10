# encoding: utf-8

import sys, os, os.path
import argparse
import re
from collections import defaultdict
from math import log
import random

START = "%"
STOP = "!"

CELEXSAMPA = "CELEXSAMPA"
CELEXSAMPANL = "CELEXSAMPANL"
CELEXSAMPADE = "CELEXSAMPADE"
CELEXSAMPALEMMA = "CELEXSAMPALEMMA"
CELEXSAMPALEMMANL = "CELEXSAMPALEMMANL"
CELEXSAMPALEMMADE = "CELEXSAMPALEMMADE"

SYLL = "SYLL"

ADDONE = "ADDONE"
NONE = "NONE"
DEFAULT_SMOOTHING = ADDONE

CORPUSTYPE = "default"
SMOOTHINGTYPE = DEFAULT_SMOOTHING
NATURAL = False
WORDNET = False

NPLUS2 = False

LN_FUNC = lambda x: log(x)
LG_FUNC = lambda x: log(x,2)
LOG_FUNC = LG_FUNC

CELEXSAMPA_VOWELS = set(["I","E","{","Q","V","U","$","3","i","1","6","u","2","4","6","7","8","#","$","9","@",":","~","5","c","q","0","C","F","H","P","R"]) 
CELEXSAMPANL_VOWELS = set(["i","y","e","|","a","o","u",")","I","E","A","O","}","@","!","(","*","<","K","L","M",":","~"])
CELEXSAMPADE_VOWELS = set(["i","y","e","|","a","o","u","#","$","3",")","I","Y","E","/","A","{","&","Q","O","}","V","U","@","c","q","0","~","^","1","2","4","6","W","B","X",":","~"])
DIPHTHVOWELS = set([":","~"])



def decompose_to_triphones(word):
    paddedword = START + START + word + STOP
    return [paddedword[i-2:i+1] for i, char in enumerate(paddedword) if i >= 2]#, [paddedword[i-1:i+1] for i, char in enumerate(paddedword) if i >= 1][:-1]

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

	
def update_counts_dicts(charfreqs, condcharfreqs, word, valueToAdd):
    for i, char in enumerate(word):
        if i > 1:
            charfreqs[char] += valueToAdd          
            condcharfreqs[char][word[i-2:i]] += valueToAdd
    return charfreqs, condcharfreqs


def read_celex_Xpl(filename, charfreqs, condcharfreqs, withdashes):
    if CORPUSTYPE == CELEXSAMPALEMMA:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),\d+,[^,]+,([^,]+)""")
    elif CORPUSTYPE == CELEXSAMPALEMMANL or CORPUSTYPE == CELEXSAMPALEMMADE:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),([^,]+)""")
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

def read_wordnet_index(filename): #returns lemma orthographic form:#senses dict
    lemmanumsensesdict = {}
    #wordnet index.* file description
    #http://wordnet.princeton.edu/wordnet/man/wndb.5WN.html
    with open(filename, "r") as f:
        for line in f:
            if line[0] == " ":
                continue
            components = line.split(" ")
            orthoform = components[0]
            numsenses = int(components[2])
            lemmanumsensesdict[orthoform] = numsenses
    return lemmanumsensesdict


def read_celex_epl_wordformdict(filename, withdashes):
    if CORPUSTYPE == CELEXSAMPALEMMA:
        findword = re.compile(r"""\d+,([^\s'-]+),\d+,\d+,[^,]+,([^,]+)""")
    elif CORPUSTYPE == CELEXSAMPALEMMANL or CORPUSTYPE == CELEXSAMPALEMMADE:
        findword = re.compile(r"""\d+,([^\s'-]+),\d+,([^,]+)""")
    #Column format: IdNum,Word,IdNumLemma,Cob,... We want Word and Cob (raw frequency)
    numtokens = 0
    wordformdict = {}
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
            phonform = match.group(2).replace(" ","").strip()
            wordform = match.group(1).replace(" ","").strip()
            wordformdict[wordform] = phonform
    return wordformdict


def make_wordnet_natural_wordsensedict(wordnetfilename, eplfilename, withdashes):
    lemmanumsensesdict = read_wordnet_index(wordnetfilename)
    wordformphonformdict = read_celex_epl_wordformdict(eplfilename, withdashes)
    wordsensedict = {}
    for lemma, numsenses in lemmanumsensesdict.iteritems():
        if lemma in wordformphonformdict:
            wordsensedict[wordformphonformdict[lemma]] = numsenses
    return wordsensedict
    

def read_celex_Xpl_natural(filename, charfreqs, condcharfreqs, withdashes):
    if CORPUSTYPE == CELEXSAMPALEMMA:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),\d+,[^,]+,([^,]+)""")
    elif CORPUSTYPE == CELEXSAMPALEMMANL or CORPUSTYPE == CELEXSAMPALEMMADE:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),([^,]+)""")
    #Column format: IdNum,Word,IdNumLemma,Cob,... We want Word and Cob (raw frequency)
    numtokens = 0
    typelemmas = defaultdict(int)
    tokenfreqs = defaultdict(int)
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
            word = match.group(2).replace(" ","").strip()
            currcount = int(match.group(1))
            if currcount == 0: 
                currcount = 1 #addone
            tokenfreqs[word] += currcount
            typelemmas[word] += 1
            paddedword = START + START + match.group(2) + STOP

            numtokens += currcount
            charfreqs, condcharfreqs = update_counts_dicts(charfreqs, condcharfreqs, paddedword, currcount)
    return tokenfreqs, typelemmas

def read_celex_Xpw(filename, charfreqs, condcharfreqs, withdashes):
    if CORPUSTYPE == CELEXSAMPA:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),[^,]+,\d+,[^,]+,([^,]+)""")
    elif CORPUSTYPE == CELEXSAMPANL or CORPUSTYPE == CELEXSAMPADE:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),\d+,([^,]+)""")
    print CORPUSTYPE
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


def read_celex_Xpw_natural(filename, charfreqs, condcharfreqs, withdashes):
    if CORPUSTYPE == CELEXSAMPA:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),[^,]+,\d+,[^,]+,([^,]+)""")
    elif CORPUSTYPE == CELEXSAMPANL or CORPUSTYPE == CELEXSAMPADE:
        findword = re.compile(r"""\d+,[^\s'-]+,(\d+),\d+,([^,]+)""")
    #Column format: IdNum,Word,IdNumLemma,Cob,... We want Word and Cob (raw frequency)
    numtokens = 0
    typelemmas = defaultdict(int)
    tokenfreqs = defaultdict(int)
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
            word = match.group(2).replace(" ","").strip()
            currcount = int(match.group(1))
            if currcount == 0: 
                currcount = 1 #addone
            tokenfreqs[word] += currcount
            typelemmas[word] += 1
            paddedword = START + START + match.group(2) + STOP

            numtokens += currcount
            charfreqs, condcharfreqs = update_counts_dicts(charfreqs, condcharfreqs, paddedword, currcount)
    return tokenfreqs, typelemmas


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


def normalize_count_func(context, contexts, freqs):
    if SMOOTHINGTYPE == ADDONE:
        if context not in contexts:
            contexts[context] += len(context)
            for char in context: 
                freqs[char] += 1
    return


def normalize_counts(freqs, condfreqs):
    for char,contexts in condfreqs.iteritems():
        for contextc in freqs.keys():        #iterate of freqs.keys() because that's guaranteed to contain all the characters    
            for contextb in freqs.keys():
                if contextc != START and contextb == START: #don't add char START context
                    continue
                normalize_count_func(contextc+contextb, contexts, freqs)
    return

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

def traverse_corpus_dir(dirname, withdashes=False):
    freqs = defaultdict(int)
    condfreqs = defaultdict(lambda : defaultdict(int))
    tokenfreqs = None
    typelemmas = None
    wcount = 0
    if CORPUSTYPE == CELEXSAMPALEMMA or CORPUSTYPE == CELEXSAMPALEMMANL or CORPUSTYPE == CELEXSAMPALEMMADE:
        if not NATURAL:
            wcount = read_celex_Xpl(dirname, freqs, condfreqs, withdashes)
        else:
            tokenfreqs, typelemmas = read_celex_Xpl_natural(dirname, freqs, condfreqs, withdashes)
            wcount = sum(tokenfreqs.values())
    else:
        if not NATURAL:
            wcount = read_celex_Xpw(dirname, freqs, condfreqs, withdashes)
        else:
            tokenfreqs, typelemmas = read_celex_Xpw_natural(dirname, freqs, condfreqs, withdashes)
            wcount = sum(tokenfreqs.values())

    normalize_counts(freqs,condfreqs)
    return freqs, condfreqs, tokenfreqs, typelemmas


def calc_probs(freqs, condfreqs, calclist=None):
    count = sum(freqs.values())
    probs = calc_char_probs_from_condfreqs(freqs, condfreqs, calclist)
    contextprobs = calc_context_probs(condfreqs, calclist)
    return probs, contextprobs


def syllable_has_one_head(word):
    if CORPUSTYPE == CELEXSAMPA:
        vowelset = CELEXSAMPA_VOWELS
    elif CORPUSTYPE == CELEXSAMPANL:
        vowelset = CELEXSAMPANL_VOWELS
    elif CORPUSTYPE == CELEXSAMPADE:
        vowelset = CELEXSAMPADE_VOWELS
    if CORPUSTYPE == CELEXSAMPALEMMA:
        vowelset = CELEXSAMPA_VOWELS
    elif CORPUSTYPE == CELEXSAMPALEMMANL:
        vowelset = CELEXSAMPANL_VOWELS
    elif CORPUSTYPE == CELEXSAMPALEMMADE:
        vowelset = CELEXSAMPADE_VOWELS

    sylls = word.split("-")
    for syll in sylls:
        numheads = 0
        for char in syll:
            if char in vowelset:
                numheads += 1
        if numheads != 1:
            return False
    
    return True

def gen_words(charprobs, contextprobs, numwords):
    wcount = 0
    worddict = defaultdict(int)
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
    numinvalidsyllwords = 0
    while wcount < numwords:
        newword = []
        nextchar = START
        prevcontext = START + START
        while nextchar == START:
            nextchar = prob_to_type(rangedicts,random.random(),prevcontext)
        
        while nextchar != STOP:
            newword.append(nextchar)
            prevcontext = prevcontext[-1] + nextchar
            nextchar = START
            while nextchar == START:
                nextchar = prob_to_type(rangedicts,random.random(),prevcontext)
        newwordstring = "".join(newword)


        if len(newwordstring) == 0 or newwordstring[0] == "-" or newwordstring[-1] == "-" or "--" in newwordstring: #don't want words beginning or ending with syllable breaks. Don't want two breaks in a row. (CELEXSAMPA)
            continue
        if not syllable_has_one_head(newwordstring):
            numinvalidsyllwords += 1
            continue

        if newwordstring not in worddict: 
                wcount += 1
        worddict[newwordstring] += 1
    return worddict


def assign_senses(worddict, assignable_senses):
    wordsensedict = defaultdict(int)
    rangedict = {}
    lowerbound = 0
    sensecount = 0
    for word, freq in worddict.iteritems():
        rangedict[(lowerbound, lowerbound + freq)] = word
        lowerbound += freq
        wordsensedict[word] += 1
    maxrand = lowerbound - 1
    while assignable_senses:
        assignment = prob_to_type(rangedict,random.randint(0,maxrand))
        wordsensedict[assignment] += 1        
        assignable_senses -= 1
        if assignable_senses % 500 == 0:
            print "Senses left to assign:\t", assignable_senses
    return wordsensedict

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

    numphones += 1 # properly handle length normalization by N+1 (i.e. the number of triphones in padded word)
    paddedword = word
    cut = 2
    paddedword = START + START + word + STOP
    for i in range(len(paddedword))[cut:]:
        currtriphone = paddedword[i-cut:i+1]
        if currtriphone in neglogprobdict:
            triphoneneglogprob = neglogprobdict[currtriphone]
            currphonsurprise += triphoneneglogprob

    phonsurprisebylen = currphonsurprise/numphones
    if NPLUS2:
        egword = "swEtS3t"
        if word == egword:
            print 'Length and phonotactic surprisal for English sample word "sweatshirt with n+1 normalization:"'
            print "\tnumphones+1:\t", numphones
            print "\tphon surprise by len:\t", phonsurprisebylen
            for i in range(len(paddedword))[cut:]:
                currtriphone = paddedword[i-cut:i+1]
                if currtriphone in neglogprobdict:
                    triphoneneglogprob = neglogprobdict[currtriphone]
                    print currtriphone, ' --- ', triphoneneglogprob

        numphones += 1 # thus normalizing by N+2
        phonsurprisebylen = currphonsurprise/numphones
        if word == egword:
            print 'Length and phonotactic surprisal for English sample word "sweatshirt with n+2 normalization:"'
            print "\tnumphones+2:\t", numphones
            print "\tphon surprise by len:\t", phonsurprisebylen

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

def unfit_freqs(word, wordfreq, charfreqdict_nodash, contextfreqdict_nodash):
    triphones = decompose_to_triphones(word)
    charfreqdict_nodash_unfitsp = charfreqdict_nodash
    contextfreqdict_nodash_unfitsp = contextfreqdict_nodash
    for triphone in triphones:
        context = triphone[0:2]
        char = triphone[2]
        subtractor = wordfreq-1
        contextfreqdict_nodash_unfitsp[char][context] -= subtractor
        charfreqdict_nodash_unfitsp[char] -= subtractor
        if charfreqdict_nodash_unfitsp[context] < 0 or contextfreqdict_nodash_unfitsp[char][context] < 0:
            raise Exception("Can't have negative counts. Word: %s, Triphone: %s, Context: %s, new Triphone Freq: %d, new Context Freq: %d, Word Freq: %d" % (word, triphone, context, contextfreqdict_nodash_unfitsp[context], charfreqdict_nodash_unfitsp[char][context], wordfreq))
    return charfreqdict_nodash_unfitsp, contextfreqdict_nodash_unfitsp

def ununfit_freqs(word, wordfreq, charfreqdict_nodash, contextfreqdict_nodash):
    triphones = decompose_to_triphones(word)
    charfreqdict_nodash_unfitsp = charfreqdict_nodash
    contextfreqdict_nodash_unfitsp = contextfreqdict_nodash
    for triphone in triphones:
        context = triphone[0:2]
        char = triphone[2]
        addator = wordfreq-1
        contextfreqdict_nodash_unfitsp[char][context] += addator
        charfreqdict_nodash_unfitsp[char] += addator
        if charfreqdict_nodash_unfitsp[context] < 0 or contextfreqdict_nodash_unfitsp[char][context] < 0:
            raise Exception("Can't have negative counts. Word: %s, Triphone: %s, Context: %s, new Triphone Freq: %d, new Context Freq: %d, Word Freq: %d" % (word, triphone, context, contextfreqdict_nodash_unfitsp[context], charfreqdict_nodash_unfitsp[char][context], wordfreq))
    return charfreqdict_nodash_unfitsp, contextfreqdict_nodash_unfitsp

def get_onsets_and_codas(dashedwordlist, vowelset):
    onsets = []
    codas = []
    for word in dashedwordlist:
        sylls = word.split("-")
        for syll in sylls:
            onset = []
            coda = []
            i = 0
            while i < len(syll) and syll[i] not in vowelset:
                onset.append(syll[i])
                i += 1
            i = len(syll) - 1
            while i >= 0 and syll[i] not in vowelset:
                coda.insert(0,syll[i])
                i -= 1
            if onset:
                onsets.append(onset)
            if coda:
                codas.append(coda)
    return onsets, codas


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
            if WORDNET: # Words from CELEX but not wordnet have no senses and should be skipped
                continue
            if not WORDNET:
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

        # CSV format:
        # word,  
        # raw word freq,   
        # word negative natural log probility,   
        # raw num word senses,   
        # word senses negative natural log probility,
        # num phones
        # num syllables
        # phonotactic surprisal divided by word length (avg phonsurprise per phone)
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
#        rounded_syllfreq_neglogprob = round(syllfreq_neglogprob,1)
#        roundedphonsurprise = round(phonsurprise,1)


        # CSV format:
        # syllable,
        # syllable token frequency
        # number of words syllable appears in
        # number of phones in syllables
        # syllable negative log probability
        # syllable phonotactic surprisal divided by syllable length
        syllmeasuredict[syll] = (str(syllfreqs[syll]),str(wordspersyll[syll]),str(numphones),str(syllfreq_neglogprob),str(phonsurprise))
    return syllmeasuredict

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Phonotactic Monkey Lexicon Generation")

    parser.add_argument("inputdir", help="directory containing corpus")
    parser.add_argument("outputfile", help="output filename; if omitted, will print debug files instead")
    parser.add_argument("numwords", help="number of words to generate", type=int)
    parser.add_argument("numsenses", help="number of senses to distribute", type=int)
    parser.add_argument("-c", "--corpustype", help="specify corpus format:  celexsampa (provide English epw file), celexsampanl (provide Dutch dpw file), celexsampade (provide German gpw file), celexsampalemma (provide English epl file)", type=str)
    parser.add_argument("--wordnet", help="read senses from wordnet. specify index.noun, index.verb, or index.adj filepath. use with --corpustyle celexsampalemma", type=str)
    parser.add_argument("-s", "--seed", help="fix random seed", type=str)
    parser.add_argument("--syll", help="calculate syllable probabilities (not implemented)", action="store_true")
    parser.add_argument("--natural", help="use actual natural language data rather than generating a PM-lexicon. Use with CELEXSAMPA* corporotypes", action="store_true")
    parser.add_argument("--nplus2", help = "normalize phonotactic surprisal by n+2 rather than by n", action="store_true")
    
    args = parser.parse_args()

    if args.numsenses < args.numwords:
        raise Exception("Number of senses cannot be less than number of word forms")

    if len(os.path.splitext(args.outputfile)) < 2:
        raise Exception("Output filename should contain an extension")

    if args.nplus2:
        NPLUS2 = True

    NATURAL = args.natural
    SMOOTHING = DEFAULT_SMOOTHING

    if args.seed != None:
        random.seed(args.seed)

    corpustype = "NONE"
    language = ""
    if args.corpustype == None:
        raise Exception("Need to pass a corpustype as input arguement")
    elif args.corpustype.lower() == "celexsampa":
        CORPUSTYPE = CELEXSAMPA
        language = "English"
    elif args.corpustype.lower() == "celexsampanl":
        CORPUSTYPE = CELEXSAMPANL
        language = "Dutch"
    elif args.corpustype.lower() == "celexsampade":
        CORPUSTYPE = CELEXSAMPADE
        language = "German"
    elif args.corpustype.lower() == "celexsampalemma":
        CORPUSTYPE = CELEXSAMPALEMMA
        language = "English"
    elif args.corpustype.lower() == "celexsampalemmanl":
        CORPUSTYPE = CELEXSAMPALEMMANL
        language = "Dutch"
    elif args.corpustype.lower() == "celexsampalemmade":
        CORPUSTYPE = CELEXSAMPALEMMADE
        language = "German"
    else:
        raise Exception("%s is not a valid corpustype" % args.corpustype)

    if args.wordnet:
        if CORPUSTYPE != CELEXSAMPALEMMA:
            raise Exception("Must use --corpustype celexsampalemma with --wordnet options")
        WORDNET = True

    #get subunit probabilities 
    dashedwords = set()
    freqs, contextfreqs, wordfreqdict, wordsensedict = traverse_corpus_dir(args.inputdir, withdashes=True)

    if WORDNET: #recalculate wordsensedict based on wordnet senses rather than celex homophones
        wordsensedict = make_wordnet_natural_wordsensedict(args.wordnet, args.inputdir, withdashes=True)
        intersectionwords = set(wordsensedict.keys()).intersection(set(wordfreqdict.keys()))
        sumsenses = 0
        for word in intersectionwords:
            sumsenses += wordsensedict[word]


    probs, contextprobs = calc_probs(freqs, contextfreqs)
    if not NATURAL:
        print "Generating PM-lexicon of type count %s" % args.numwords
        wordfreqdict = gen_words(probs, contextprobs, args.numwords)


    sortedwords = sorted(wordfreqdict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]

    #assign senses
    assignable_senses = args.numsenses-args.numwords
    if not NATURAL: #if you comment this, then you assign senses to actual vocab in NATURAL mode
        print "Assigning %s additional senses" % assignable_senses
        wordsensedict = assign_senses(wordfreqdict, assignable_senses)
    sortedwordsenses = sorted(wordsensedict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]

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
    wordmetricdict, charneglogprobdict = gen_metrics(wordfreqdict, wordsensedict, probs, contextprobs, syllabifications)
    with open(args.outputfile,"w") as f:
        f.write("word,wordfreq,wordneglogprob,numwordsenses,wordsensesneglogprob,numphones,numsylls,phonsuprise\n")
        for word, tup in wordmetricdict.iteritems():
            f.write("%s,%s\n"%(word,",".join(tup)))
    sortedcharneglogprobs = sorted(charneglogprobdict.iteritems(), key = lambda (k,v): (float(v),k), reverse=True)#[0:100]
    with open(os.path.splitext(args.outputfile)[0] + "_ps" + os.path.splitext(args.outputfile)[1],"w") as f:
        for char, neglogprob in sortedcharneglogprobs:
            f.write("%s,%s\n"%(char,neglogprob))

    if CORPUSTYPE != CELEXSAMPALEMMA:
        # CSV format:
        # syllable,
        # syllable token frequency
        # number of words syllable appears in
        # number of phones in syllables
        # syllable negative log probability
        # syllable phonotactic surprisal divided by syllable length
        syllmetricdict = gen_syll_metrics(wordfreqdict, wordsensedict, probs, syllabifications)
        with open(args.outputfile.replace(".csv","_sylls.csv"),"w") as f:
            f.write("syll,syllfreq,wordspersyll,numphones,syllneglogprob,phonsurprise\n")
            for syll, tup in syllmetricdict.iteritems():
                f.write("%s,%s\n"%(syll,",".join(tup)))

    pos = ""
    if CORPUSTYPE == CELEXSAMPALEMMA:
        pos = "POS "
    if not NATURAL:
        print "This %s %smonkey is done @(･o･)@" % (language,pos)
    else:
        print "These natural %s %smetrics have been calculated :-)" % (language,pos)
