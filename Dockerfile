#
# This container will allow you to run MSLT by blast against assemblies using the schemes from PubMLST
#
FROM debian:testing

#
# Authorship
#
MAINTAINER ap13@sanger.ac.uk

#
# Set environment variables
#
ENV MLST_DATABASES /MLST_databases

#
# Update and Install dependencies
#
RUN apt-get update -qq && apt-get install -y wget ncbi-blast+ cpanminus gcc autoconf make libxml2-dev zlib1g zlib1g-dev libmodule-install-perl && cpanm -f Bio::MLST::Check

RUN mkdir -p /example && cd /example && \
    wget -O sample1.fa https://github.com/sanger-pathogens/mlst_check/raw/master/example/input_data/Salmonella_enterica_subsp_enterica_serovar_Typhi_str_CT18_v1.fa && \
    wget -O sample2.fa https://github.com/sanger-pathogens/mlst_check/raw/master/example/input_data/Salmonella_enterica_subsp_enterica_serovar_Typhimurium_DT104_v1.fa && \
    wget -O sample3.fa https://github.com/sanger-pathogens/mlst_check/raw/master/example/input_data/Salmonella_enterica_subsp_enterica_serovar_Weltevreden_str_10259_v0.2.fa
    
#
# Download the databases from PubMLST
#
RUN download_mlst_databases

#
# Set the directory to be the shared dir
#
WORKDIR /data
