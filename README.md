
#Cpp based tools for barcoded RNAseq

##TL;DR Summary

Set of cpp tools for UMI based RNAseq. These are decendants of python scripts used to split fastq files before alignment and merge files after alignment by bwa. All the binaries are multithreaded unless otherwise stated.

Installation: From the source directory 
	make clean; make  (NWELLS=96/384 - default is 96) 

For all binaries the -h flag gives documentation about the available flags and an example of how to use the binary: 

umisplit_orig	: takes pairs of R1 and R2 fastq files and generates a new fastq file with the UMI from the R2 file merged to the header line of the R1 file

umisplit: takes pairs of R1 and R2 fastq files and generates a new fastq file with the UMI from the R2 file merged to the header line of the R1 file. It also separates the reads based on the plate well barcode part of the UMI

umisplit_sam: takes a set of sam files produced by umisplit_orig or the original split_and_align python script and splits the lines into separate files based on the barcode of the UMI

umimerge: takes a set of sam files produced by umisplit and counts the reads mapped to each gene and plate well - single threaded

umimerge_single_pass: same as umi_merge but attempts to count multiple alignments and unique alignments in a single pass at the cost of more RAM (~20 GB required ) - single threaded

umimerge_parallel: takes sam files organized by plate wells and counts the reads mapped to each gene - multithreaded and has option of using position level filtering by UMIs

umisample: simple utility to create smaller files from subsets of lines of fastq files for testing purposes

multbwa.sh bash a directory for sam files and run bwa in parallel

##Publication

The results and description of the methodology are [here](https://www.biorxiv.org/content/early/2018/06/14/345819)

The scripts used to produce the results in the publication are given in the scripts directory. To reproduce the results download the sample data and directories from [here](https://drive.google.com/open?id=15poX9BP3v7b_jk3fL8miq_spmsAn8V2B)

Copy the archive to the github repo directory - then:

	tar -xjf dtoxs_data.tar.bz2
	cd dtoxs
	#to run original python 2 scripts on test data
	scripts/run_alignment.sh ${PWD}
	#to run optimized software
	scripts/fast_run_alignment.sh ${PWD}

The above scripts come with short versions of the fastq files for testing. The complete dataset used in the publication is available [here](https://www.ncbi.nlm.nih.gov/sra?term=SRP106034)



##Building and executing the software using Docker
The build.sh script creates a minimum container from scratch. This is done in 2 steps - a full build environment to compile the code and then a minimal environment for the runtime execs. Alternatively you can just pull it from our biodepot repot

To execute the docker container (for 96 well plates): (sudo may not be necessary depending on your docker [setup](https://docs.docker.com/install/linux/linux-postinstall/))

	sudo docker run --rm -v <myVolume>/<containerVolume>  biodepot/rna-umi-cpp:3.7-1.0 <cmd> <arguments>

For 384 well plates:
	
	sudo docker run --rm -e NWELLS=384 biodepot/rna-umi-cpp:3.7-1.0 <cmd> <arguments>

The optimized software can be run on the dtoxs test cases using docker by invoking the docker script i.e.

	tar -xjf dtoxs_data.tar.bz2
	cd dtoxs
	scripts/docker_fast_run_alignment.sh ${PWD}
	
The docker script gives an example of how to use the Docker containers.

