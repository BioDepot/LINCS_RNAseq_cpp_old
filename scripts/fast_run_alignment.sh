#!/bin/bash
# This script converts a series of mRNA sequencing data file in FASTQ format
# to a table of UMI read counts of human genes in multiple sample conditions.


# 1 Parameters

# 1.1 Global


TOP_DIR=$1

# 1.2 Dataset
SERIES="20150409"
SAMPLE_ID="RNAseq_${SERIES}"
LANES=6
DATA_DIR=$TOP_DIR
SEQ_DIR="${DATA_DIR}/Seqs"
ALIGN_DIR="${DATA_DIR}/Aligns"
COUNT_DIR="${DATA_DIR}/Counts"
UMITOOLS_DIR="${TOP_DIR}/LINCS_RNAseq_cpp" #where the cpp repo is

# 1.3 Reference
REF_DIR="$TOP_DIR/References/Broad_UMI"
SPECIES_DIR="${REF_DIR}/Human_RefSeq"
REF_SEQ_FILE="${SPECIES_DIR}/refMrna_ERCC_polyAstrip.hg19.fa"
SYM2REF_FILE="${SPECIES_DIR}/refGene.hg19.sym2ref.dat"
ERCC_SEQ_FILE="${REF_DIR}/ERCC92.fa"
BARCODE_FILE="${REF_DIR}/barcodes_trugrade_96_set4.dat"

# 1.4 Program
PROG_DIR="$TOP_DIR/Programs/Broad-DGE"
BWA_ALN_SEED_LENGTH=24
BWA_SAM_MAX_ALIGNS_FOR_XA_TAG=20
THREAD_NUMBER=4

# 2 Computation

# 2.1 Alignment
# Align sequence fragments to reference genome library.
let "IDX = 1"	
SEQ_FILES="";
#get files
while [ "$IDX" -le "${LANES}" ]; do
	SUBSAMPLE_ID="Lane$IDX"
	SEQ_FILE_R1="${SEQ_DIR}/${SAMPLE_ID}_${SUBSAMPLE_ID}_R1.fastq.gz"
	SEQ_FILE_R2="${SEQ_DIR}/${SAMPLE_ID}_${SUBSAMPLE_ID}_R2.fastq.gz"
	SEQ_FILES="${SEQ_FILES} ${SEQ_FILE_R1} ${SEQ_FILE_R2}"
	let "IDX = $IDX + 1"
done	
 #split into wells
 #use tight checking no mismatch no ambiguities to match original - default is the looser setting of mismatch =1 and missing N=1 

mkdir -p $TOP_DIR/cppTimeLogs
echo "/usr/bin/time -v $UMITOOLS_DIR/source/umisplit -v -l 16 -m 0 -N 1 -f -o $ALIGN_DIR -t $THREAD_NUMBER -b $BARCODE_FILE $SEQ_FILES 2> $TOP_DIR/cppTimeLogs/cppSplitTimeLog\n"
/usr/bin/time -v $UMITOOLS_DIR/source/umisplit -v -l 16 -m 0 -N 1 -f -o $ALIGN_DIR -t $THREAD_NUMBER -b $BARCODE_FILE $SEQ_FILES 2> $TOP_DIR/cppTimeLogs/cppSplitTimeLog
echo "/usr/bin/time -v $UMITOOLS_DIR/scripts/multibwa.sh $TOP_DIR $REF_DIR $SPECIES_DIR $ALIGN_DIR $BWA_ALN_SEED_LENGTH $BWA_SAM_MAX_ALIGNS_FOR_XA_TAG $THREAD_NUMBER 2> $TOP_DIR/cppTimeLogs/cppBwaTimeLog\n"
/usr/bin/time -v $UMITOOLS_DIR/scripts/multibwa.sh $TOP_DIR $REF_DIR $SPECIES_DIR $ALIGN_DIR $BWA_ALN_SEED_LENGTH $BWA_SAM_MAX_ALIGNS_FOR_XA_TAG $THREAD_NUMBER 2> $TOP_DIR/cppTimeLogs/cppBwaTimeLog
echo "/usr/bin/time -v $UMITOOLS_DIR/source/umimerge_parallel -i $SAMPLE_ID -s $SYM2REF_FILE -e $ERCC_SEQ_FILE -b $BARCODE_FILE -a $ALIGN_DIR -o $COUNT_DIR -t $THREAD_NUMBER 2> $TOP_DIR/cppTimeLogs/cppMergeTimeLog\n"
/usr/bin/time -v $UMITOOLS_DIR/source/umimerge_parallel -i $SAMPLE_ID -s $SYM2REF_FILE -e $ERCC_SEQ_FILE -b $BARCODE_FILE -a $ALIGN_DIR -o $COUNT_DIR -t $THREAD_NUMBER 2> $TOP_DIR/cppTimeLogs/cppMergeTimeLog

