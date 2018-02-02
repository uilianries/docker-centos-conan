FROM centos:6.9

# Install python 2.7 and PyLDAP dependencies
RUN yum update -y \
    && yum install -y centos-release-scl epel-release \
    && yum install -y python27 openssl-devel openldap-devel libgsasl-devel sudo \
    && yum groupinstall -y "Development tools"

# Create conan user
RUN useradd -ms /bin/bash conan \
    && usermod -aG wheel conan \
    && printf "conan:conan" | chpasswd \
    && printf "conan ALL= NOPASSWD: ALL\\n" >> /etc/sudoers \

# Change to user conan
USER conan

# Add python on PATH
ENV LD_LIBRARY_PATH=/opt/rh/python27/root/usr/lib64/
ENV PATH=/opt/rh/python27/root/usr/bin:${PATH}

# Update python name
RUN alias python=/opt/rh/python27/root/usr/bin/python2.7 \
    && alias pip=/opt/rh/python27/root/usr/bin/pip2.7

# Install conan
RUN sudo pip install -U pip \
    && sudo pip install conan==1.0.1 \
    && conan user

# Create ~/.conan_server
RUN timeout 2s conan_server || true

# Install LDAP plugin at ~/.conan_server/plugin/authenticator
RUN sudo pip install conan-ldap-authentication==0.2.0

# Set Conan server to run LDAP plugin
RUN sed -i 's/# custom_authenticator: my_authenticator/custom_authenticator: ldap_authentication/g' ${HOME}/.conan_server/server.conf

CMD ["conan_server"]
