# Apollo2.X
FROM ubuntu:18.04
MAINTAINER Nathan Dunn <nathandunn@lbl.gov>
ENV DEBIAN_FRONTEND noninteractive


# where bin directories are
ENV CATALINA_HOME /usr/share/tomcat9
# where webapps are deployed
ENV CATALINA_BASE /var/lib/tomcat9
ENV CONTEXT_PATH ROOT
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install \
	git locales locales-all build-essential libpq-dev wget python3-pip \
	lsb-release gnupg2 wget xmlstarlet netcat libpng-dev postgresql-common \
	zlib1g-dev libexpat1-dev curl ssl-cert zip unzip openjdk-8-jdk-headless

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install \
	postgresql-9.6 postgresql-client-9.6  tomcat9 && \
	apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /apollo/

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install nodejs


RUN curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/blat/blat" -o /usr/local/bin/blat && \
 		chmod +x /usr/local/bin/blat && \
 		curl -s "http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit" -o /usr/local/bin/faToTwoBit && \
 		chmod +x /usr/local/bin/faToTwoBit && \
		wget --quiet https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins26/chado-1.31.sql.gz -O /chado.sql.gz && \
		gunzip /chado.sql.gz

#NOTE, we had problems with the build the archive-file coming in from github so using a clone instead
RUN npm i -g yarn &&  useradd -ms /bin/bash -d /apollo apollo
COPY client /apollo/client
COPY gradlew /apollo
COPY grails-app /apollo/grails-app
COPY gwt-sdk /apollo/gwt-sdk
COPY lib /apollo/lib
COPY src /apollo/src
COPY web-app /apollo/web-app
COPY wrapper /apollo/wrapper
COPY test /apollo/test
COPY scripts /apollo/scripts
ADD gra* /apollo/
COPY apollo /apollo/apollo
ADD build* /apollo/
ADD settings.gradle /apollo
ADD application.properties /apollo

COPY docker-files/build.sh /bin/build.sh
ADD docker-files/docker-apollo-config.groovy /apollo/apollo-config.groovy
ADD docker-files/agr-apollo-load.sql /agr-apollo-load.sql
RUN chown -R apollo:apollo /apollo
RUN ls -la /apollo

# install grails and python libraries
USER apollo

# fix for pip install decode error 
# RUN locale-gen en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN pip3 install setuptools
RUN pip3 install wheel
RUN pip3 install nose apollo==4.2.7

RUN curl -s get.sdkman.io | bash && \
     /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && yes | sdk install grails 2.5.5" && \
     /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && yes | sdk install gradle 3.2.1"

RUN /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && /bin/bash /bin/build.sh"

USER root
# remove from webapps and copy it into a staging directory
RUN rm -rf ${CATALINA_BASE}/webapps/* && \
	cp /apollo/apollo*.war ${CATALINA_BASE}/apollo.war

ADD docker-files/createenv.sh /createenv.sh
ADD docker-files/launch.sh /launch.sh

RUN pwd
WORKDIR /

RUN git clone --single-branch --branch release-3.2.0 https://github.com/alliance-genome/agr_jbrowse_config.git jbrowse
RUN chown -R apollo:apollo /jbrowse
WORKDIR /jbrowse/scripts
RUN pwd
RUN ./fetch_vcf.sh apollo


CMD "/launch.sh"

# wait and add organisms after launch if not already there, or do it in the launch script
# bumping for rebuilding docker 
