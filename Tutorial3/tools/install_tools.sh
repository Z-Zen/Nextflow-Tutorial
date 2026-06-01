#!/bin/bash

# check if snpEff_latest_core.zip is already downloaded
if [ -f $1/snpEff_latest_core.zip ]; then
    echo "snpEff_latest_core.zip already downloaded"
else
    wget https://downloads.sourceforge.net/project/snpeff/snpEff_latest_core.zip -O $1/snpEff_latest_core.zip
fi

# check if  snpEff is unzipped
if [ -d $1/snpEff ]; then
    echo "snpEff already unzipped"
else
    unzip $1/snpEff_latest_core.zip -d $1
fi

# check if bcftools is already installed (stable, version-independent path)
if [ -x $1/bcftools/bcftools ]; then
    echo "bcftools already installed"
else
    apt-get install -y libcurl4-openssl-dev
    # resolve the latest bcftools version from the GitHub API
    BCFTOOLS_VERSION=$(curl -fsSL https://api.github.com/repos/samtools/bcftools/releases/latest \
        | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    echo "Installing latest bcftools: ${BCFTOOLS_VERSION}"
    wget https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2 -O $1/bcftools-${BCFTOOLS_VERSION}.tar.bz2
    tar -xjf $1/bcftools-${BCFTOOLS_VERSION}.tar.bz2 -C $1
    make --directory $1/bcftools-${BCFTOOLS_VERSION}/ -j
    # expose the build under a stable path so Nextflow needn't know the version
    ln -sfn $1/bcftools-${BCFTOOLS_VERSION} $1/bcftools
fi
