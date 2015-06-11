# (C) Copyright IBM Corporation 2014.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:14.04

MAINTAINER David Currie <david_currie@uk.ibm.com> (@dcurrie)

RUN apt-get update \
    && apt-get install -y wget \
	&& apt-get install -y unzip \
    && rm -rf /var/lib/apt/lists/*

# Install JRE
ENV JRE_VERSION 1.7.1_sr2fp10
RUN JRE_URL=$(wget -q -O - https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/jre/index.yml | sed -n '/'$JRE_VERSION'/{n;p}' | sed -n 's/\s*uri:\s//p' | tr -d '\r') \
    && wget -q $JRE_URL -U UA-IBM-WebSphere-Liberty-Docker -O /tmp/ibm-java.bin \
    && chmod +x /tmp/ibm-java.bin \
    && echo "INSTALLER_UI=silent" > /tmp/response.properties \
    && echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties \
    && mkdir /opt/ibm \
    && /tmp/ibm-java.bin -i silent -f /tmp/response.properties \
    && rm /tmp/response.properties \
    && rm /tmp/ibm-java.bin
ENV JAVA_HOME /opt/ibm/java
ENV PATH $JAVA_HOME/jre/bin:$PATH

# Install WebSphere Liberty
ENV LIBERTY_VERSION 2015.5.0_0
ADD wlp-beta-kernel-2015.6.0.0.zip /tmp/
RUN unzip /tmp/wlp-beta-kernel-2015.6.0.0.zip -d /opt/ibm \
	&& sudo rm -rf /tmp/
COPY liberty-run /opt/ibm/wlp/bin/
ENV PATH /opt/ibm/wlp/bin:$PATH

# Configure WebSphere Liberty
RUN /opt/ibm/wlp/bin/server create \
    && rm -rf /opt/ibm/wlp/usr/servers/.classCache
    && featureManager install jaxrs-2.0 --when-file-exists=ignore
COPY server.xml /opt/ibm/wlp/usr/servers/defaultServer/
	&& ExampleJaxrs.war /opt/ibm/wlp/usr/servers/defaultServer/dropins/
EXPOSE 9080
EXPOSE 9443

ENTRYPOINT ["liberty-run"]
CMD ["/opt/ibm/wlp/bin/server", "run", "defaultServer"]
