FROM debian:wheezy
MAINTAINER Michael Zender <michael@crazymonkeys.de>


RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget git\
		ruby1.8 libmysqlclient-dev libmagickwand-dev\
		apache2 libapache2-mod-passenger
RUN DEBIAN_FRONTEND=noninteractive apt-get clean

WORKDIR /tmp

RUN wget http://production.cf.rubygems.org/rubygems/rubygems-1.7.2.tgz \
	&& tar -xf rubygems-1.7.2.tgz \
	&& rm rubygems-1.7.2.tgz \
	&& mv rubygems-1.7.2 /usr/lib/ \
	&& cd /usr/lib/rubygems-1.7.2 \
	&& ruby setup.rb

RUN wget --no-check-certificate https://github.com/redmine/redmine/archive/1.3.0.tar.gz \
	&& tar -xf 1.3.0.tar.gz \
	&& rm 1.3.0.tar.gz \
	&& mv redmine-1.3.0 redmine \
	&& mv redmine /usr/local/lib

RUN gem1.8 install rack -v=1.1.6 --no-rdoc --no-ri \
	&& gem1.8 install rake -v=0.8.7 --no-rdoc --no-ri \
	&& gem1.8 install i18n -v=0.4.2 --no-rdoc --no-ri \
	&& gem1.8 install rails -v=2.3.14 --no-rdoc --no-ri \
	&& gem1.8 install rdoc -v=2.4.2 --no-rdoc --no-ri \
	&& gem1.8 install mysql --no-rdoc --no-ri \
	&& gem1.8 install rmagick --no-rdoc --no-ri \
	&& gem1.8 install json --no-rdoc --no-ri

ADD database.yml /usr/local/lib/redmine/config/database.yml
ADD configuration.yml /usr/local/lib/redmine/config/configuration.yml
ADD apache-config /etc/apache2/sites-available/default

WORKDIR /usr/local/lib/redmine

RUN mkdir -p files log public/plugin_assets tmp \
	&& chown -R www-data:www-data files log tmp public/plugin_assets \
	&& chmod -R 755 files log tmp \
	&& chmod -R 777 public/plugin_assets \
	&& rake generate_session_store

WORKDIR /usr/local/lib/redmine/vendor/plugins

RUN git clone https://github.com/koppen/redmine_github_hook.git \
	&& cd redmine_github_hook \
	&& git checkout redmine_1.x

VOLUME ["/usr/local/lib/redmine/files", "/var/redmine"]

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
