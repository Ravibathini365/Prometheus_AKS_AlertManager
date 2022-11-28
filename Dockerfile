FROM vscojfrogrhel.vsazure.com/rhel-ubi-images/ubi8:latest

## Define some args that get passed at build time.
##
ARG TIME_STAMP

## Security Team Requirements
##
# start code here

## Infra Team Tuneables
##
# Point the rhel ubi public repos to artifactory's proxied repos
RUN sed -i 's/https\:\/\/cdn-ubi\.redhat\.com\/content\/public\/ubi/https\:\/\/vscojfrogrhel\.vsazure\.com\/artifactory\/rhel-ubi-base/g' /etc/yum.repos.d/ubi.repo

# Copy to image more repos to be included.
COPY ./rhel_8_repos/*.repo /etc/yum.repos.d/

# Make sure packages are up-to-date, patch system
# Add timestamp file for extra image tagging
RUN touch /tmp/${TIME_STAMP} && \
    yum --disableplugin=subscription-manager update -y

RUN yum --disableplugin=subscription-manager install iputils bind-utils telnet -y --nobest

COPY alertmanager-0.23.0.linux-amd64/amtool       /bin/amtool
COPY alertmanager-0.23.0.linux-amd64/alertmanager /bin/alertmanager
COPY ./alertmanager.yml /etc/alertmanager/alertmanager.yml

RUN mkdir -p /alertmanager && \
    chown -R nobody:nobody etc/alertmanager /alertmanager

USER       nobody
EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/alertmanager.yml", \
             "--storage.path=/alertmanager" ]
#             "--web.external-url=http://etoprometheusalertmanager.etocore.eastus2.vsazure.com" ]
