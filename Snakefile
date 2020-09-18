"""
Master Snakefile for running the Hecatomb pipeline on HTCF.

Rachel Rodgers, Sep 2020
""" 

import os
import sys
sys.path.append("./scripts")

from hecatomb_helpers import *

#----- Snakemake Set Up -----#

configfile: "config.yaml"

# Hecatomb DB paths
CONPATH = config["Paths"]["Contaminants"]
HOSTPATH = config["Paths"]["Host"]
BACPATH = config["Paths"]["Bacteria"]
AATARGET = config["Paths"]["TargetMMseqsAA"]
AATARGETCHECK = config["Paths"]["TargetMMseqsAACheck"]
NTTARGET = config["Paths"]["TargetMMseqsNT"]

# Data paths
READDIR = config["Paths"]["Reads"]

# File paths
PHAGE = config["DatabaseFiles"]["Phage"]
NCBIACC = config["DatabaseFiles"]["NCBIAccession"] # write to file so R can read in

# Java memory
XMX = config["System"]["Memory"]

# Tools
BBTOOLS = config["Tools"]["BBTools"]
R = config["Tools"]["R"]
SEQKIT = config["Tools"]["Seqkit"]
PULLSEQ = config["Tools"]["Pullseq"]
MMSEQS = config["Tools"]["MMseqs"]

#----- Rename input files if there are any to rename -----#

rename_files(config)

#----- Collect the Input Files -----#

# Pull sample names from the renamed R1 files in /data/renamed/ and store in a list
SAMPLES, = glob_wildcards(os.path.join(READDIR, "renamed", "{sample}_R1.fastq.gz"))

PATTERN_R1 = "{sample}_R1"
PATTERN_R2 = "{sample}_R2"

#----- Snakemake Workflow -----# 

#----- Contaminant Removal -----#
include: "contaminant_removal.snakefile"
#----- Cluster Count -----#
include: "cluster_count.snakefile"
#----- Merge Sequencing Tables -----#
include: "seqtable_merge.snakefile"
#----- MMSeqs2 Query Viral Seqs Against AA DB -----#
include: "mmseqs_pviral_aa.snakefile"
#----- MMSeqs2 Query Probable Viral Seqs Against UniClust 30 proteinDB -----#
include: "mmseqs_pviral_aa_check.snakefile"
#----- MMSeqs2 Query AA Unclassified Seqs Against Refseq Virus NT UniVec Masked -----#
include: "mmseqs_pviral_nt.snakefile"


rule all:
	input:
		os.path.join("results", "mmseqs_aa_out", "phage_tax_table.tsv"),
		os.path.join("results", "mmseqs_aa_out", "aln.m8"),
		os.path.join("results", "mmseqs_aa_checked_out", "aln.m8"),
		os.path.join("results", "mmseqs_aa_checked_out", "taxonomyResult.firsthit.m8"),
		os.path.join("results", "mmseqs_aa_checked_out", "taxonomyResult.tsv"),
		os.path.join("results", "mmseqs_aa_checked_out", "viruses_checked_aa_tax_table.tsv"),
		os.path.join("results", "mmseqs_aa_checked_out", "unclassified_checked_aa_seqs.fasta"),
		os.path.join("results", "mmseqs_nt_out", "resultDB.firsthit.m8")

rule clean:
	shell:
		"rm -rf ./QC/ ./clumped/"
