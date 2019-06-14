FROM ubuntu:18.04 as builder


RUN apt-get update && apt-get install -y \
        bash \
        build-essential  \
        gcc \
        git \
        wget \
        gfortran \
        unzip

# Get RTKLIB and compile only required components
ARG RTKLIB_URL=https://github.com/rtklibexplorer/RTKLIB.git
ARG RTKLIB_TAG=demo5 
RUN git clone --depth 1 --branch ${RTKLIB_TAG} ${RTKLIB_URL} \
    && (cd RTKLIB/lib/iers/gcc/; make) \
    && (cd RTKLIB/app/convbin/gcc/; make; make install) \
    && (cd RTKLIB/app/rnx2rtkp/gcc/; make; make install) \
    && (cd RTKLIB/app/pos2kml/gcc/; make; make install) \
    && (cd RTKLIB/app/str2str/gcc/; make; make install) \
    && (cd RTKLIB/app/rtkrcv/gcc/; make; make install) 

# get conf file
ARG CONF_URL=https://raw.githubusercontent.com/rinex20/gnss_tools/master/conf/rtkrcv.conf
RUN mkdir ~/rtk \
    && mkdir ~/rtk/conf \
    && wget --no-check-certificate ${CONF_URL} -O ~/rtk/conf/rtkrcv.conf

# teqc
ARG TEQC_URL=https://www.unavco.org/software/data-processing/teqc/development/teqc_CentOSLx86_64s.zip
RUN wget --no-check-certificate ${TEQC_URL} -O teqc.zip \
 && unzip teqc.zip 

# hatanaka
ARG HATANAKA_URL=http://terras.gsi.go.jp/ja/crx2rnx/RNXCMP_4.0.7_Linux_x86_64bit.tar.gz
RUN wget ${HATANAKA_URL} -O /tmp/hatanaka.tgz \
 && tar xvfz /tmp/hatanaka.tgz

# GFZRNX
RUN wget http://semisys.gfz-potsdam.de/semisys/software/gfzrnx/1.11/gfzrnx_lx \
 && chmod ugo+x gfzrnx_lx \
 && mv gfzrnx_lx /usr/local/bin/ \
 && (cd /usr/local/bin/; ln -s gfzrnx_lx gfzrnx)

FROM ubuntu:18.04

RUN apt-get update && apt-get install -y csh

COPY --from=builder /usr/local/bin/* teqc RNXCMP_*/bin/* /usr/local/bin/

# run rtkrcv
EXPOSE 8077 8078 82001-82008
CMD ["rtkrcv", "-p 8077 -m 8078 -o ~/rtk/conf/rtkrcv.conf"] 
