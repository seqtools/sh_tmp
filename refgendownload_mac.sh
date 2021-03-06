#!/bin/bash
#
# Installation script for automatically setting up reference genome files.
#
# This script has two arguments. The first one is genomebuild and the second one is the full path of a folder to which user want to save the downloade files. 
# 5/8/2021 Change igenome links.

set -e

# trap ctrl-c and SIGHUP. Call ctrl_c() to handle
trap ctrl_c INT SIGHUP

function ctrl_c() {
        echo "Trapped CTRL-C or SIGHUP"
}

function checkfile {
	if [ ! -f "${1}" ] 
	then 
		echo "Error: ${1} could not be found."
		exit 5 
	fi
	
	if [ ! -s "${1}" ] 
	then 
		echo "Error: the size of ${1} is zero. The file was not successfully downloaded."
		exit 5 
	fi
	
}

function checkmulfiles {
	if ! ls "${1}"/${2} >/dev/null;
	then 
		echo "Error: ${1}/${2} could not be found."
		exit 5 
	fi
}

function downloadIGenomes {
(echo Step 3 Downloading the iGenomes file...; date) | sed 'N;s/\n/ /'
LINK="http://igenomes.illumina.com.s3-website-us-east-1.amazonaws.com/Homo_sapiens/${1}/${2}/Homo_sapiens_${1}_${2}.tar.gz"
curl -L --cookie /tmp/cookie.txt --cookie-jar /tmp/cookie.txt $LINK -o Homo_sapiens_${1}_${2}.tar.gz
checkfile Homo_sapiens_${1}_${2}.tar.gz

dir="Homo_sapiens/${1}/${2}/Sequence/WholeGenomeFasta"
if [ ! -d $dir ]; then mkdir -p $dir; fi;
tar -xvf $PWD/Homo_sapiens_${1}_${2}.tar.gz $dir/genome.fa $dir/genome.fa.fai $dir/genome.dict $dir/GenomeSize.xml
#cp -RLp ~/.avfs"$PWD/Homo_sapiens_${1}_${2}.tar.gz#"/$dir/{genome.fa,genome.fa.fai,genome.dict,GenomeSize.xml} $PWD/$dir
checkfile $PWD/$dir/genome.fa
checkfile $PWD/$dir/genome.fa.fai
checkfile $PWD/$dir/genome.dict
checkfile $PWD/$dir/GenomeSize.xml
echo "genome reference files have been downloaded successfully."
(echo Step 4 Extracting the iGenomes file...; date) | sed 'N;s/\n/ /'
if [ ${2} == "GRCh37" ]; then
	dir="Homo_sapiens/${1}/${2}/Annotation/Archives/archive-2015-07-17-14-31-42/Genes"
fi

if [ ${2} == "GRCh38" ]; then
	dir="Homo_sapiens/${1}/${2}/Annotation/Archives/archive-2015-08-11-09-31-31/Genes"
fi

if [ ${2} == "hg19" ]; then
	dir="Homo_sapiens/${1}/${2}/Annotation/Archives/archive-2015-07-17-14-32-32/Genes"
fi

if [ ${2} == "hg38" ]; then
	dir="Homo_sapiens/${1}/${2}/Annotation/Archives/archive-2015-08-14-08-18-15/Genes"
fi
dirGene="Homo_sapiens/${1}/${2}/Annotation/Genes"
if [ ! -d $dirGene ]; then mkdir -p $dirGene; fi;
tar -xvf $PWD/Homo_sapiens_${1}_${2}.tar.gz $dir/genes.gtf
mv $PWD/$dir/genes.gtf $PWD/$dirGene/
rm -r -f $PWD/Homo_sapiens/${1}/${2}/Annotation/Archives
#cp -RLp ~/.avfs"$PWD/Homo_sapiens_${1}_${2}.tar.gz#"/$dir/genes.gtf $PWD/$dirGene
checkfile $PWD/$dirGene/genes.gtf
echo "genes.gtf has been downloaded successfully."

dir="Homo_sapiens/${1}/${2}/Sequence/BWAIndex/version0.6.0"
dirBWA="Homo_sapiens/${1}/${2}/Sequence/BWAIndex"
if [ ! -d $dirBWA ]; then mkdir -p $dirBWA; fi;
tar -xvf $PWD/Homo_sapiens_${1}_${2}.tar.gz $dir/genome.fa.bwt $dir/genome.fa.ann $dir/genome.fa.amb $dir/genome.fa.pac $dir/genome.fa.sa
mv $dir/* $dir/..
rm -r -f $dir
#cp -RLp ~/.avfs"$PWD/Homo_sapiens_${1}_${2}.tar.gz#"/$dir/{genome.fa.bwt,genome.fa.ann,genome.fa.amb,genome.fa.pac,genome.fa.sa} $PWD/$dirBWA
checkfile $PWD/$dirBWA/genome.fa.bwt
checkfile $PWD/$dirBWA/genome.fa.ann
checkfile $PWD/$dirBWA/genome.fa.amb
checkfile $PWD/$dirBWA/genome.fa.pac
checkfile $PWD/$dirBWA/genome.fa.sa
echo "BWA pre-built index files have been downloaded successfully."

dir="Homo_sapiens/${1}/${2}/Sequence/Bowtie2Index"
if [ ! -d $dir ]; then mkdir -p $dir; fi;
tar -xvf $PWD/Homo_sapiens_${1}_${2}.tar.gz $dir/*.bt2
#cp -RLp ~/.avfs"$PWD/Homo_sapiens_${1}_${2}.tar.gz#"/$dir/*.bt2 $PWD/$dir
checkmulfiles $PWD/$dir *.bt2
echo "Bowtie2 pre-built index files have been downloaded successfully."

}

(echo Start; date) | sed 'N;s/\n/ /'
echo $1
echo $2
echo $PWD

#mountavfs

cd $2

#Create a folder
mkdir -p ./RefGenProfiles
mkdir -p ./RefGenProfiles/dbSNP_VCF
case $1 in
	"Ensembl_GRCh37") 
		cd ./RefGenProfiles
		cd ./dbSNP_VCF
		mkdir -p ./Ensembl_GRCh37
		cd ./Ensembl_GRCh37
		(echo Step 1 Downloading the dbSNP_tbi file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz.tbi -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/GATK/common_all_20170710.vcf.gz.tbi)
		(echo Step 2 Downloading the dbSNP_vcf file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/GATK/common_all_20170710.vcf.gz)
		(checkfile common_all_20170710.vcf.gz) 
		(checkfile common_all_20170710.vcf.gz.tbi) 
		cd ../..
		(downloadIGenomes Ensembl GRCh37)
		rm ${2}/RefGenProfiles/Homo_sapiens_Ensembl_GRCh37.tar.gz
		;;
	"NCBI_GRCh38")
		cd ./RefGenProfiles
		cd ./dbSNP_VCF
		mkdir -p ./NCBI_GRCh38
		cd ./NCBI_GRCh38
		(echo Step 1 Downloading the dbSNP_tbi file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz.tbi -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/VCF/GATK/common_all_20170710.vcf.gz.tbi)
		(echo Step 2 Downloading the dbSNP_vcf file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/VCF/GATK/common_all_20170710.vcf.gz)
		(checkfile common_all_20170710.vcf.gz) 
		(checkfile common_all_20170710.vcf.gz.tbi) 
		cd ../..
		(downloadIGenomes NCBI GRCh38)
		rm ${2}/RefGenProfiles/Homo_sapiens_NCBI_GRCh38.tar.gz
		;;
	"UCSC_hg38")
		cd ./RefGenProfiles
		cd ./dbSNP_VCF
		mkdir -p ./UCSC_hg38
		cd ./UCSC_hg38
		(echo Step 1 Downloading the dbSNP_tbi file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz.tbi -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/VCF/GATK/common_all_20170710.vcf.gz.tbi)
		(echo Step 2 Downloading the dbSNP_vcf file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/VCF/GATK/common_all_20170710.vcf.gz)
		(checkfile common_all_20170710.vcf.gz) 
		(checkfile common_all_20170710.vcf.gz.tbi)
		cd ../..
		(downloadIGenomes UCSC hg38)
		rm ${2}/RefGenProfiles/Homo_sapiens_UCSC_hg38.tar.gz
		;;
	"UCSC_hg19") 
		cd ./RefGenProfiles		
		cd ./dbSNP_VCF
		mkdir -p ./UCSC_hg19
		cd ./UCSC_hg19
		(echo Step 1 Downloading the dbSNP_tbi file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz.tbi -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/GATK/common_all_20170710.vcf.gz.tbi)
		(echo Step 2 Downloading the dbSNP_vcf file...; date) | sed 'N;s/\n/ /'
		(curl -L -o common_all_20170710.vcf.gz -C - https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/GATK/common_all_20170710.vcf.gz)
		(checkfile common_all_20170710.vcf.gz) 
		(checkfile common_all_20170710.vcf.gz.tbi) 
		cd ../..
		(downloadIGenomes UCSC hg19)
		rm ${2}/RefGenProfiles/Homo_sapiens_UCSC_hg19.tar.gz
		;;
esac
(echo Step 5 Downloading finished.; date) | sed 'N;s/\n/ /'
