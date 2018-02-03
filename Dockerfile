FROM centos:6.9

# Install development tools and PyLAP dependencies
RUN yum update -y \
    && yum install -y epel-release \
    && yum install -y openssl-devel openldap-devel libgsasl-devel sudo wget curl sqlite-devel \
    && yum groupinstall -y "Development tools"

# Install Python 2.7
RUN wget -q -O /tmp/python-2.7.tar.gz https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz \
    && tar xzf /tmp/python-2.7.tar.gz -C /tmp \
    && cd /tmp/Python-2.7.10 \
    && ./configure --prefix=/usr/bin \
    && make \
    && make install \
    && cd -

# install Python pip
RUN curl -k https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && /usr/bin/python2.7 /tmp/get-pip.py --prefix=/usr/local

# Create conan user
RUN useradd -ms /bin/bash conan \
    && usermod -aG wheel conan \
    && printf "conan:conan" | chpasswd \
    && printf "conan ALL= NOPASSWD: ALL\\n" >> /etc/sudoers \
    && su - conan

# Install conan
RUN sudo /usr/local/bin/pip install -U pip \
    && sudo /usr/local/bin/pip install conan==1.0.1 \
    && conan user

# Create ~/.conan_server
RUN timeout 2s conan_server || true

# Install LDAP plugin at ~/.conan_server/plugin/authenticator
RUN sudo /usr/local/bin/pip install conan-ldap-authentication==0.2.2

# Set Conan server to run LDAP plugin
RUN sed -i 's/# custom_authenticator: my_authenticator/custom_authenticator: ldap_authentication/g' ${HOME}/.conan_server/server.conf

# Change to user conan
USER conan

CMD ["conan_server"]
