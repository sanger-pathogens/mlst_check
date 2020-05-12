#
# This container will allow you to run MSLT by blast against assemblies using the schemes from PubMLST
#
FROM ubuntu:20.04

LABEL maintainer=path-help@sanger.ac.uk

ARG DEBIAN_FRONTEND=noninteractive

RUN   apt-get update -qq && \
      apt-get install -y locales && \
      sed -i -e 's/# \(en_GB\.UTF-8 .*\)/\1/' /etc/locale.gen && \
      touch /usr/share/locale/locale.alias && \
      locale-gen
ENV   LANG     en_GB.UTF-8
ENV   LANGUAGE en_GB:en
ENV   LC_ALL   en_GB.UTF-8

#
# Set environment variables
#
ENV MLST_DATABASES /MLST_databases

#
# Update and Install dependencies
#
RUN   apt-get update -qq && \
      apt-get install -y wget ncbi-blast+ cpanminus gcc autoconf make libxml2-dev zlib1g zlib1g-dev libmodule-install-perl && \
      # expat required for current versions of various XML packages in CPAN
      apt-get install -y libexpat1-dev && \
      # there's a known issue with one of the tests in XML::DOM::XPath
      cpanm -notest XML::DOM::XPath && \
      # install CPAN modules without --force so errors aren't hidden
      cpanm Bio::MLST::Check

# copy whatever example files are provided in the branch/tag that we're building from
COPY  ./example/input_data/*.fa /example/
    
#
# Download the databases from PubMLST
#
RUN download_mlst_databases

#
# Set the directory to be the shared dir
#
WORKDIR /data
