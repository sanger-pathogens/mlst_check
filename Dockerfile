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
RUN apt-get update -qq && apt-get install -y ncbi-blast+ cpanminus gcc autoconf make libxml2-dev zlib1g zlib1g-dev libmodule-install-perl && cpanm -f Bio::MLST::Check

#
# Download the databases from PubMLST
#
RUN download_mlst_databases

#
# Set the directory to be the shared dir
#
WORKDIR /data
