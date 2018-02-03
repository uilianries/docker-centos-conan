FROM centos:6.9

ENV PATH=/usr/local/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/lib

# Install development tools and PyLAP dependencies
RUN yum update -y \
    && yum install -y epel-release \
    && yum install -y openssl-devel openldap-devel libgsasl-devel sudo wget curl sqlite-devel \
    && yum groupinstall -y "Development tools"

# Install Python 2.7
RUN wget -q -O /tmp/python-2.7.tar.gz https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz \
    && tar xzf /tmp/python-2.7.tar.gz -C /tmp \
    && cd /tmp/Python-2.7.10 \
    && ./configure \
    && make \
    && make install \
    && cd -

# install Python pip
RUN curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && python /tmp/get-pip.py

# Create conan user
RUN useradd -ms /bin/bash conan \
    && usermod -aG wheel conan \
    && printf "conan:conan" | chpasswd \
    && printf "conan ALL= NOPASSWD: ALL\\n" >> /etc/sudoers \
    && su - conan

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

# Change to user conan
USER conan

CMD ["conan_server"]
