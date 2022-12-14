#!/bin/bash

# check if snpEff_latest_core.zip is already downloaded
if [ -f $1/snpEff_latest_core.zip ]; then
    echo "snpEff_latest_core.zip already downloaded"
else
    wget https://snpeff.blob.core.windows.net/versions/snpEff_latest_core.zip -O $1/snpEff_latest_core.zip
    # check if  snpEff is unzipped
    if [ -d $1/snpEff ]; then
        echo "snpEff already unzipped"
    else
        unzip $1/snpEff_latest_core.zip -d $1
    fi
fi


# check if bcftools 1.16 is already installed
if [ -f $1/bcftools-1.16/bcftools ]; then
    echo "bcftools already installed"
else
    apt-get install  libcurl4-openssl-dev
    wget https://github.com/samtools/bcftools/releases/download/1.16/bcftools-1.16.tar.bz2 -O $1/bcftools-1.16.tar.bz2
    tar -xjf $1/bcftools-1.16.tar.bz2 -C $1
    make --directory $1/bcftools-1.16/ -j
fi
