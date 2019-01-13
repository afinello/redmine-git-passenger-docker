FROM redmine:3.3-passenger

EXPOSE 3000/tcp
# for git ssh
EXPOSE 22/tcp

# install dependencies
RUN apt-get update && apt-get install -y \
	build-essential \
	cmake \
	debconf-utils \
	pkg-config \
	imagemagick \
	libmagickwand-dev \
	openssh-server \
	libssh2-1 \
	libssh2-1-dev \
	libssl-dev \
	libgpg-error-dev \
	curl \
	sudo
	
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# prevent permission error when running bundle install
RUN chown -R redmine:redmine /usr/local/bundle

# prepare redmine user for gitolite
RUN mkdir -p /home/redmine/.ssh && \
    usermod --shell /bin/bash redmine && \
    ssh-keygen -N '' -f /home/redmine/.ssh/redmine_gitolite_admin_id_rsa && \
    mkdir -p /home/redmine/tmp && \
    chmod 777 /home/redmine/tmp && \
    chown -R redmine:redmine /home/redmine

# install gitolite as user git
RUN useradd -m git

# -  login to "git" on the server
# -  make sure your ssh public key from your workstation has been copied as $HOME/YourName.pub
RUN cd /home/git && \
    sudo -HEu git git clone git://github.com/sitaramc/gitolite /home/git/gitolite && \
    sudo -HEu git mkdir -p /home/git/bin && \
    sudo -HEu git gitolite/install -to /home/git/bin

# setup gitolite
ENV PATH="${PATH}:/home/git/bin"
RUN cd /home/git && \
    sudo -HEu git /home/git/bin/gitolite setup -pk /home/redmine/.ssh/redmine_gitolite_admin_id_rsa.pub
# configure gitolite
RUN gosu git mkdir -p /home/git/local && \
    gosu git sed -i "s#GIT_CONFIG_KEYS.*#GIT_CONFIG_KEYS  =>  '.*',#" /home/git/.gitolite.rc && \
	gosu git sed -i -e "s/# LOCAL_CODE.*=>.*\"\$ENV{HOME}\/local\"/LOCAL_CODE => \"\/home\/git\/local\"/" /home/git/.gitolite.rc

RUN sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config
#RUN sed -i -e "s/AcceptEnv LANG .*/#AcceptEnv LANG LC_\*/g" /etc/ssh/sshd_config

RUN echo "Defaults:redmine !requiretty\nredmine ALL=(git) NOPASSWD:ALL\n" >> /etc/sudoers.d/redmine
RUN chmod 440 /etc/sudoers.d/redmine

# install plugins
COPY ./plugins /usr/src/redmine/plugins

# clone redmine git hosting repository & fix dependency problem
RUN cd /usr/src/redmine/plugins && \
    git clone https://github.com/jbox-web/redmine_bootstrap_kit.git -b 0.2.5 && \
    git clone https://github.com/jbox-web/redmine_git_hosting.git -b 1.2.3 && \
    sed -i -e "s/gem 'redcarpet'.*/gem 'redcarpet', '~> 3.3.2'/g" ./redmine_git_hosting/Gemfile
#RUN cd /usr/src/redmine/plugins && \ 
#    echo "gem 'gitlab-grack', git: 'https://github.com/jbox-web/grack.git', require: 'grack', branch: 'fix_rails3'" >> ./redmine_git_hosting/Gemfile
RUN gosu git mkdir -p /home/git/recycle_bin

# clone themes
RUN cd /usr/src/redmine/public/themes && \
    git clone https://github.com/tsi/redmine-theme-flat.git redmine-theme-flat && \
    git clone https://github.com/hardpixel/minelab.git minelab && \
    git clone https://github.com/makotokw/redmine-theme-gitmike.git redmine-theme-gitmike

RUN cp /usr/src/redmine/Gemfile.lock.mysql2 /usr/src/redmine/Gemfile.lock && \
    gosu redmine sh -c "bundle install --without development test" && \
    gosu redmine sh -c "rake generate_secret_token"

VOLUME /home/git/repositories

COPY ./gitolite-entrypoint.sh /gitolite-entrypoint.sh

ENTRYPOINT ["/gitolite-entrypoint.sh"]
CMD ["passenger", "start"]
