#!/bin/bash
# This script converts a series of mRNA sequencing data file in FASTQ format
# to a table of UMI read counts of human genes in multiple sample conditions.

check_program ()
{
	if [ -z "$(which $1)" ]; then
		echo "ERROR: "$1" is not found!" 1>&2
		exit 1
	fi
}

# 1 Parameters

# 1.1 Global

TOP_DIR=$1

# 1.2 Dataset
SERIES=${ENV_SERIES_NAME}
if [ -z "$ENV_SERIES_NAME" ]; then SERIES="20150409"; fi
BARCODE_FILENAME=${ENV_BARCODE_FILE}
if [ -z "$BARCODE_FILENAME" ]; then BARCODE_FILENAME="barcodes_trugrade_96_set4.dat"; fi
LANES=${ENV_LANES}
if [ -z "$ENV_LANES" ]; then LANES=6; fi
echo ${SERIES}
echo ${BARCODE_FILENAME}
echo ${LANES}
SAMPLE_ID="RNAseq_${SERIES}"
DATA_DIR=$TOP_DIR
SEQ_DIR="${DATA_DIR}/Seqs"
ALIGN_DIR="${DATA_DIR}/Aligns"
COUNT_DIR="${DATA_DIR}/Counts"

# 1.3 Reference
REF_DIR="$TOP_DIR/References/Broad_UMI"
SPECIES_DIR="${REF_DIR}/Human_RefSeq"
REF_SEQ_FILE="${SPECIES_DIR}/refMrna_ERCC_polyAstrip.hg19.fa"
SYM2REF_FILE="${SPECIES_DIR}/refGene.hg19.sym2ref.dat"
ERCC_SEQ_FILE="${REF_DIR}/ERCC92.fa"
BARCODE_FILE="${REF_DIR}/${BARCODE_FILENAME}"

# 1.4 Program
#uncomment if default implementation of python is Python 2.7
#PYTHON=python 
PYTHON=python2
PROG_DIR="$TOP_DIR/Programs/Broad-DGE"
BWA_ALN_SEED_LENGTH=24
BWA_SAM_MAX_ALIGNS_FOR_XA_TAG=20
THREAD_NUMBER=4

# 2 Computation

check_program "bwa"

# 2.1 Alignment
# Align sequence fragments to reference genome library.
let "IDX = 1"
mkdir -p $TOP_DIR/pyTimeLogs
let "SIDX=1"
while [ "$IDX" -le "${LANES}" ]; do
	SUBSAMPLE_ID="Lane$IDX"
	SEQ_FILE_R1="${SEQ_DIR}/${SAMPLE_ID}_${SUBSAMPLE_ID}_R1.fastq.gz"
	SEQ_FILE_R2="${SEQ_DIR}/${SAMPLE_ID}_${SUBSAMPLE_ID}_R2.fastq.gz"
	# Split input paired FASTQ files to multiple intermediate FASTQ files.
	echo "/usr/bin/time -v ${PYTHON} ${PROG_DIR}/split_and_align.py" "${SAMPLE_ID}" "${SUBSAMPLE_ID}" "${SEQ_FILE_R1}" "${SEQ_FILE_R2}" "${ALIGN_DIR}/" "${REF_SEQ_FILE} 2> ${TOP_DIR}/pyTimeLogs/pSplitTimeLog$IDX "
	/usr/bin/time -v ${PYTHON} "${PROG_DIR}/split_and_align.py" "${SAMPLE_ID}" "${SUBSAMPLE_ID}" "${SEQ_FILE_R1}" "${SEQ_FILE_R2}" "${ALIGN_DIR}/" "${REF_SEQ_FILE}" 2> ${TOP_DIR}/pyTimeLogs/pySplitTimeLog$IDX
	# Align individual intermediate FASTQ files.
	OLD_IFS=$IFS
	IFS=$'\n'
	for SEQ_FILE in $(find "${ALIGN_DIR}" -maxdepth 1 -name "${SAMPLE_ID}\.${SUBSAMPLE_ID}*\.fastq" -printf "%p$IFS"); do
		SAM_FILE="${SEQ_FILE}.sam"
		 #/usr/bin/time -v  bwa aln -l "${BWA_ALN_SEED_LENGTH}" -t "${THREAD_NUMBER}" "${REF_SEQ_FILE}" "${SEQ_FILE}" 2> ${TOP_DIR}/pyTimeLogs/pyBwaAlnTimeLog$SIDX | /usr/bin/time -v bwa samse -n "${BWA_SAM_MAX_ALIGNS_FOR_XA_TAG}" "${REF_SEQ_FILE}" - "${SEQ_FILE}" > "${SAM_FILE}" 2> ${TOP_DIR}/pyTimeLogs/pyBwaSamTimeLog$SIDX
		/usr/bin/time -vf "%es" bash -c "bwa aln -l \"${BWA_ALN_SEED_LENGTH}\" -t \"${THREAD_NUMBER}\" \"${REF_SEQ_FILE}\" \"${SEQ_FILE}\"  | bwa samse -n \"${BWA_SAM_MAX_ALIGNS_FOR_XA_TAG}\" \"${REF_SEQ_FILE}\" - \"${SEQ_FILE}\" > \"${SAM_FILE}\""  2> ${TOP_DIR}/pyTimeLogs/pyBwaSamTimeLog$SIDX 
		let "SIDX = $SIDX + 1"
	done
	IFS=$OLD_IFS
	let "IDX = $IDX + 1"
done

# 2.2 Counting
# Count the number of sequence alignments for reference genes.
/usr/bin/time -v ${PYTHON} "${PROG_DIR}/merge_and_count.py" "${SAMPLE_ID}" "${SYM2REF_FILE}" "${ERCC_SEQ_FILE}" "${BARCODE_FILE}" "${ALIGN_DIR}/" "${COUNT_DIR}/" False 2> ${TOP_DIR}/pyTimeLogs/pyBwaJoinLog$IDX

exit 0
