#########################
#########################
## Define input and output directories
#########################
#########################
datadir="data"
outputdir="outputs"
CURRDIR=$(pwd)


#########################
#########################
## Use CKY counts or PTG counts
#########################
#########################
USE_CURRENT_COUNTS=true
# True here is CKY counts
# Else uses PTG

if [ "$USE_CURRENT_COUNTS" = true ] ; then
	echo "Using CKY sense and type counts"
	#from empirical (index.* files)
	ENGLISH_TYPE_CNT_NOUN=20620
	ENGLISH_SENSE_CNT_NOUN=40621
	ENGLISH_TYPE_CNT_VERB=6243
	ENGLISH_SENSE_CNT_VERB=17113
	ENGLISH_TYPE_CNT_ADJ=7680
	ENGLISH_SENSE_CNT_ADJ=14250

	#from empirical (Xpw/not lemma)
	ENGLISH_TYPE_CNT_ALL=65355
	ENGLISH_SENSE_CNT_ALL=119266
	DUTCH_TYPE_CNT_ALL=279314
	DUTCH_SENSE_CNT_ALL=343713
	GERMAN_TYPE_CNT_ALL=309741
	GERMAN_SENSE_CNT_ALL=321101
else
	echo "Using PTG sense and type counts"
	#From PTG
	ENGLISH_TYPE_CNT_NOUN=20586
	ENGLISH_SENSE_CNT_NOUN=41206
	ENGLISH_TYPE_CNT_VERB=3175
	ENGLISH_SENSE_CNT_VERB=10358
	ENGLISH_TYPE_CNT_ADJ=1536
	ENGLISH_SENSE_CNT_ADJ=3770

	#from PTG
	ENGLISH_TYPE_CNT_ALL=65417
	ENGLISH_SENSE_CNT_ALL=77243
	DUTCH_TYPE_CNT_ALL=277522
	DUTCH_SENSE_CNT_ALL=292563
	GERMAN_TYPE_CNT_ALL=310668
	GERMAN_SENSE_CNT_ALL=319579
fi


########################
########################
# English Polysemy PM Generation and Calculation
########################
########################
echo "English Polysemy PM Generation and Calculation..."
echo "... nouns"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_PM_CELEXSAMPALEMMA_noun.csv $ENGLISH_TYPE_CNT_NOUN $ENGLISH_SENSE_CNT_NOUN -s seed0
echo "... verbs"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_PM_CELEXSAMPALEMMA_verb.csv $ENGLISH_TYPE_CNT_VERB $ENGLISH_SENSE_CNT_VERB -s seed0
echo "... adjectives"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_PM_CELEXSAMPALEMMA_adj.csv $ENGLISH_TYPE_CNT_ADJ $ENGLISH_SENSE_CNT_ADJ -s seed0


#########################
#########################
## English Polysemy Natural Calculation
#########################
#########################
echo "English Polysemy Natural Calculation..."
echo "... nouns"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_CELEXSAMPALEMMA_actual_noun.csv 0 0 -s seed0 --natural --wordnet data/wordnet3db/index.noun
echo "... verbs"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_CELEXSAMPALEMMA_actual_verb.csv 0 0 -s seed0 --natural --wordnet data/wordnet3db/index.verb
echo "... adjectives"
python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_CELEXSAMPALEMMA_actual_adj.csv 0 0 -s seed0 --natural --wordnet data/wordnet3db/index.adj


#########################
#########################
## Homophony and Syllable Informativity PM/PSM Generation and Calculation
#########################
#########################
echo "Homophony and Syllable Informativity PM/PSM Generation and Calculation..."
echo "... PM-English"
python themonkey.py -c celexsampa $datadir/epw.csv $outputdir/output_CELEXSAMPA_homophony.csv $ENGLISH_TYPE_CNT_ALL $ENGLISH_SENSE_CNT_ALL -s seed0
echo "... PM-Dutch"
python themonkey.py -c celexsampanl $datadir/dpw.csv $outputdir/output_CELEXSAMPANL_homophony.csv $DUTCH_TYPE_CNT_ALL $DUTCH_SENSE_CNT_ALL -s seed0
echo "... PM-German"
python themonkey.py -c celexsampade $datadir/gpw.csv $outputdir/output_CELEXSAMPADE_homophony.csv $GERMAN_TYPE_CNT_ALL $GERMAN_SENSE_CNT_ALL -s seed0
echo "... PSM English"
python themeaningfulmonkey.py $datadir/epw.csv $outputdir/output_CELEXSAMPA_PSM_1.csv 700000 700000 -s seed0 -t 0.1


#########################
#########################
## Homophony and Syllable Informativity Natural Calculation
#########################
#########################
echo "Homophony and Syllable Informativity Natural Calculation..."
echo "... Natural-English"
python themonkey.py -c celexsampa $datadir/epw.csv $outputdir/output_CELEXSAMPA_actual_homophony.csv 0 0 -s seed0 --natural
echo "... Natural-English with N+2 normalization"
python themonkey.py -c celexsampa $datadir/epw.csv $outputdir/output_CELEXSAMPA_NPLUS2_actual_homophony.csv 0 0 -s seed0 --natural --nplus2
echo "... Natural-Dutch"
python themonkey.py -c celexsampanl $datadir/dpw.csv $outputdir/output_CELEXSAMPANL_actual_homophony.csv 0 0 -s seed0 --natural
echo "... Natural-German"
python themonkey.py -c celexsampade $datadir/gpw.csv $outputdir/output_CELEXSAMPADE_actual_homophony.csv 0 0 -s seed0 --natural

## Uncomment below to plot comparison of N+1 and N+2 normalization for actual-English
# echo "... plotting N+1 vs. N+2 normalization"
# Rscript phonSurpriseNormalizationPlot.R $CURRDIR $outputdir/ output_CELEXSAMPA_actual_homophony.csv output_CELEXSAMPA_NPLUS2_actual_homophony.csv


#########################
#########################
## Fit Regressions for PTG Correlations
#########################
#########################
echo "... Fit Regressions for PTG Correlations"
Rscript regressionAnalysis.R $CURRDIR $outputdir $datadir/regression_input_list.txt
Rscript regressionAnalysis_sylls.R $CURRDIR $outputdir $datadir/regression_sylls_input_list.txt


# #########################
# #########################
# ## OED and PSM Calculations
# #########################
# #########################
OED_EPL_Metrics="output_CELEXSAMPALEMMA_actual_newLM_metrics.csv"
OED_NF_Metrics="epl_onlyOED_NF_withLength_metrics.csv"
OED_RF_Metrics="epl_onlyOED_RF_withLength_metrics.csv"
OED_SF_Metrics="epl_onlyOED_SF_withLength_metrics.csv"
OEDprime_Header="output_CELEXSAMPA_PSM_1_OEDprimesource_175k"
OEDprime_Metrics="output_CELEXSAMPA_PSM_1_OEDprimesource_175k_metrics.csv"
OEDprime_Chronology="output_CELEXSAMPA_PSM_1_OEDprimesource_175k_grafted_chron.txt"
PSM_Chronology="output_CELEXSAMPA_PSM_1_chron.txt"

echo "... make Voronoi diagram from PSM output"
Rscript PSM-field-plot.R $CURRDIR $outputdir/ $PSM_Chronology 1
echo "... plot OED vs. PSM form/sense ratio"
Rscript diachonicSensePlot.R $CURRDIR $outputdir/ $datadir/OEDbyyear.txt $PSM_Chronology

echo "... intersect OED data with CELEX"
python intersectOEDwithCelex.py $datadir/OEDold.txt $datadir/OEDnew.txt $datadir/epl.csv $datadir/epl_onlyOED_NF.csv $datadir/epl_onlyOED_RF.csv $datadir/epl_onlyOED_SF.csv $datadir/epl_onlyOED_RFuSF.csv

echo "... generate and collate OED-prime"
python convertXplToXpw.py $datadir/epl_onlyOED_RFuSF.csv $datadir/epl_reformat_onlyOED_RFuSF.csv
python themeaningfulmonkey.py $datadir/epl_reformat_onlyOED_RFuSF.csv $outputdir/"${OEDprime_Header}".csv 175000 175000 -s seed0 -t 0.1
python graftmonkey.py $outputdir/"${OEDprime_Header}"_chron.txt $datadir/epl_reformat_onlyOED_RFuSF.csv $outputdir/$OEDprime_Chronology --length 120000

echo "... add length information to OED data"
python themonkey.py -c celexsampalemma $datadir/epl_onlyOED_NF.csv $outputdir/epl_onlyOED_NF_withLength.csv 0 0 -s seed0 --natural 
python themonkey.py -c celexsampalemma $datadir/epl_onlyOED_RF.csv $outputdir/epl_onlyOED_RF_withLength.csv 0 0 -s seed0 --natural
python themonkey.py -c celexsampalemma $datadir/epl_onlyOED_SF.csv $outputdir/epl_onlyOED_SF_withLength.csv 0 0 -s seed0 --natural

echo "... train LM over Celex EPL Pre-1900 forms"
python themonkey.py -c celexsampalemma $datadir/epl_onlyOED_RFuSF.csv $outputdir/epl_onlyOED_pre1900.csv 0 0 -s seed0 --natural
echo "... apply LM to OED data to compute PhonSurprise"
python phonsurprise.py $outputdir/epl_onlyOED_NF_withLength.csv $outputdir/epl_onlyOED_pre1900_ps.csv $outputdir/$OED_NF_Metrics
python phonsurprise.py $outputdir/epl_onlyOED_RF_withLength.csv $outputdir/epl_onlyOED_pre1900_ps.csv $outputdir/$OED_RF_Metrics
python phonsurprise.py $outputdir/epl_onlyOED_SF_withLength.csv $outputdir/epl_onlyOED_pre1900_ps.csv $outputdir/$OED_SF_Metrics
python phonsurprise.py $outputdir/"${OEDprime_Header}".csv $outputdir/epl_onlyOED_pre1900_ps.csv $outputdir/$OEDprime_Metrics

python themonkey.py -c celexsampalemma $datadir/epl.csv $outputdir/output_CELEXSAMPAlemma_actual_all.csv 0 0 -s seed0 --natural
python phonsurprise.py $outputdir/output_CELEXSAMPAlemma_actual_all.csv $outputdir/epl_onlyOED_pre1900_ps.csv $outputdir/$OED_EPL_Metrics 

echo "... perform Monkey vs. Actual English RF/SF/NF comparisons (with three different stopping conditions for Monkey English lexicon size)"
Rscript OED_vs_monkey_RFNF_Analysis.R $CURRDIR $outputdir/ 'MatchBoth' $OED_EPL_Metrics $OED_NF_Metrics $OED_RF_Metrics $OED_SF_Metrics $OEDprime_Metrics $OEDprime_Chronology
## Uncomment below to run matching only RF count or only NF count rather than matching both
# Rscript OED_vs_monkey_RFNF_Analysis.R $CURRDIR $outputdir/ 'MatchRF' $OED_EPL_Metrics $OED_NF_Metrics $OED_RF_Metrics $OED_SF_Metrics $OEDprime_Metrics $OEDprime_Chronology
# Rscript OED_vs_monkey_RFNF_Analysis.R $CURRDIR $outputdir/ 'MatchNF' $OED_EPL_Metrics $OED_NF_Metrics $OED_RF_Metrics $OED_SF_Metrics $OEDprime_Metrics $OEDprime_Chronology


#########################
#########################
## PTG-style correlation Plots
#########################
#########################
echo "Make Plots..."
echo "... PM-Lexicon Plots"
Rscript makePlots_homophony.R $CURRDIR $outputdir/ PM output_CELEXSAMPA_homophony.csv output_CELEXSAMPANL_homophony.csv output_CELEXSAMPADE_homophony.csv allPlots-homophony-PM.png
Rscript makePlots_polysemy.R $CURRDIR $outputdir/ PM output_PM_CELEXSAMPALEMMA_noun.csv output_PM_CELEXSAMPALEMMA_verb.csv output_PM_CELEXSAMPALEMMA_adj.csv allPlots-polysemy-PM.png
Rscript makePlots_sylls.R $CURRDIR $outputdir/ PM output_CELEXSAMPA_homophony_sylls.csv output_CELEXSAMPANL_homophony_sylls.csv output_CELEXSAMPADE_homophony_sylls.csv allPlots-sylls-PM.png
echo "... Natural-Lexicon Plots"
Rscript makePlots_homophony.R $CURRDIR $outputdir/ Natural output_CELEXSAMPA_actual_homophony.csv output_CELEXSAMPANL_actual_homophony.csv output_CELEXSAMPADE_actual_homophony.csv allPlots-homophony-actual.png
Rscript makePlots_polysemy.R $CURRDIR $outputdir/ Natural output_CELEXSAMPALEMMA_actual_noun.csv output_CELEXSAMPALEMMA_actual_verb.csv output_CELEXSAMPALEMMA_actual_adj.csv allPlots-polysemy-actual.png
Rscript makePlots_sylls.R $CURRDIR $outputdir/ Natural output_CELEXSAMPA_actual_homophony_sylls.csv output_CELEXSAMPANL_actual_homophony_sylls.csv output_CELEXSAMPADE_actual_homophony_sylls.csv allPlots-sylls-actual.png
echo "... PSM-Lexicon Plots"
Rscript makePlots_homophony.R $CURRDIR $outputdir/ PSM output_CELEXSAMPA_PSM_1.csv allPlots-homophony-PSM.png
Rscript makePlots_sylls.R $CURRDIR $outputdir/ PSM output_CELEXSAMPA_PSM_1_sylls.csv allPlots-sylls-PSM.png


#########################
#########################
## Final clean up of output directory
#########################
#########################
echo "Cleaning up output directory"...
rm ./$outputdir/Rplots.pdf # Remove extraneous "Rplots.pdf" if ggplot decides to create it
mkdir ./$outputdir/plots/
mv ./$outputdir/*.png ./$outputdir/plots/
mkdir ./$outputdir/stats/
mv ./$outputdir/*__stats.* ./$outputdir/stats/
mkdir ./$outputdir/LMs/
mv ./$outputdir/*_ps.csv ./$outputdir/LMs/
mkdir ./$outputdir/lexicons/
mv ./$outputdir/output_*.csv ./$outputdir/lexicons/
mv ./$outputdir/*_chron.txt ./$outputdir/lexicons/
mv ./$outputdir/epl_onlyOED_*.csv ./$outputdir/lexicons/


#########################
#########################
## Finished
#########################
#########################
echo "(-:  Completed  :-)"
