#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  Ubuntu 14+, Debian 7+                       #
#   One click Install Apache+OpenSSL+Nghttp2                      #
#   Author: Baka-Network <contact@baka.network>                   #
#=================================================================#

clear
echo
echo "################################################################"
echo "# One click Install Apache+OpenSSL+Nghttp2                     #"
echo "# Author: Baka-Network(Baka-D) <contact@baka.network>          #"
echo "################################################################"
echo

echo
echo "################################################################"
echo "# NOTICE:                                                      #"
echo "# The script will install all the softwares into /opt/LAON.    #"
echo "################################################################"
echo

# Make sure only root can run our script
rootness(){
    if [[ $EUID -ne 0 ]]; then
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

# Disable selinux
disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

pre_install(){
    # Set Nghttp2 Version
    echo -e "Please enter the version number you want to install for Nghttp2:"
    read -p "(Default Version: 1.36.0):" nh2version
    [ -z "$nh2version" ] && nh2version="1.36.0"
    # Confirm Location
    # echo -e "Is this machine in Mainland China? (y/n):"
    # read -p "(Default :n):" chinaornot
    #[ -z "$chinaornot" ] && chinaornot="n"
	# Set Node.js Version
    # echo "Please input the version of Node.js:"
    # read -p "(Default Version: stable [eg:stable,lts,6.6.0]):" nodeversion
    # [ -z "${nodeversion}" ] && nodeversion="stable"
	# Set HEXO Directory
    # [ -z "${hexopath}" ] && hexopath="/var/www/blog"
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    #Install necessary dependencies
    apt-get update -y
    apt-get upgrade -y
    apt-get install build-essential unzip gcc make automake python autoconf libtool* libexpat1-dev -y
}

# Making File-Cache Dir
make_dir(){
    mkdir /opt/LAON
    mkdir /opt/LAON/tmp
    cd /opt/LAON/tmp
}

# Install Apr
install_apr(){
    echo "Installing Apr"
    cd /opt/LAON/tmp
    if ! git clone https://github.com/apache/apr -b trunk; then
	echo -e "[${red}Error${plain}] Failed to download Apr source files!"
        exit 1
    fi
    cd apr
    ./buildconf
    ./configure --prefix=/opt/LAON/apr
    make && make install
}

# Install Zlib
install_zlib(){
    echo "Installing Zlib"
    cd /opt/LAON/tmp && wget http://zlib.net/zlib-1.2.11.tar.gz
    tar -zxf zlib-1.*.tar.gz
    rm zlib-1.*.tar.gz
    cd zlib-1.*
    ./configure --prefix=/usr/local
    make && make install
}

# Install Pcre
install_pcre(){
    echo "Installing Pcre"
    cd /opt/LAON/tmp && wget https://ftp.pcre.org/pub/pcre/pcre-8.41.tar.gz
    tar -zxf pcre-*.tar.gz
    rm pcre-*.tar.gz
    cd pcre-*
    ./configure --prefix=/opt/LAON/pcre
    make && make install
}

# Install OpenSSL
install_openssl(){
    echo "Installing OpenSSL"
    cd /opt/LAON/tmp 
    if ! git clone --recurse-submodules https://github.com/openssl/openssl; then
	echo -e "[${red}Error${plain}] Failed to download OpenSSL source files!"
        exit 1
    fi
    cd openssl
    ./config --prefix=/opt/LAON/openssl enable-zlib enable-shared enable-tls1_3
    if ! make; then
        echo -e "[${red}Error${plain}] Failed to build OpenSSL!"
        exit 1
    fi
    make install
}

# Install Nghttp2
install_nghttp2(){
    echo "Installing Nghttp2"
    cd /opt/LAON/tmp  
    if ! wget --no-check-certificate https://github.com/nghttp2/nghttp2/releases/download/v${nh2version}/nghttp2-${nh2version}.tar.gz; then
	echo -e "[${red}Error${plain}] Failed to download Nghttp2 source files!"
        exit 1
    fi
    tar -zxf nghttp2*.tar.gz
    cd nghttp2-${nh2version}
    ./configure --prefix=/opt/LAON/nghttp2
    make && make install
}

# Install Apache
install_apache(){
    echo "Installing Apache"
    cd /opt/LAON/tmp
    if ! git clone https://github.com/apache/httpd -b trunk; then
	echo -e "[${red}Error${plain}] Failed to download Httpd source files!"
        exit 1
    fi
    cd httpd
    ln -s /opt/LAON/tmp/apr srclib/apr
    ./buildconf
    ./configure --prefix=/opt/LAON/httpd --enable-deflate --enable-expires --enable-headers --enable-modules=all --enable-so --enable-mpm --with-mpm=event --enable-rewrite --with-apr=/opt/LAON/apr --with-pcre=/opt/LAON/pcre/bin/pcre-config --enable-ssl --enable-rewrite --enable-http2 --with-nghttp2=/opt/LAON/nghttp2 --with-ssl=/opt/LAON/openssl --with-crypto --enable-ssl-ct
    if ! make; then
        echo -e "[${red}Error${plain}] Failed to build Httpd!"
        exit 1
    fi
    make install
}

# Install HEXO
#install_hexo(){
    #npm install n -g
    #n ${nodeversion}
    #npm install hexo-cli -g
    #mkdir /var/www
    #mkdir /var/www/blog
    #hexo init ${hexopath}
    #cd ${hexopath}
    #npm install
#}

# Config
config(){
    echo "Configing"
    #chown www-root:www-root /var/www/blog/public -R
    #chmod 755 /var/www/blog/public -R
    cp /opt/LAON/openssl/lib/* /usr/lib/ -R -f
    cp /opt/LAON/httpd/bin/* /usr/bin/ -R -f
    cp /opt/LAON/nghttp2/lib/* /usr/lib/ -R -f
    
}

# Delete Downloaded File
delete_files(){
    echo "Deleting useless files"
    rm -rf /opt/LAON/tmp
    echo "Install Complete!"
}

# Install LAON
install_LAON(){
    rootness
    disable_selinux
    pre_install
    make_dir
    install_apr
    #install_apr_util
    install_zlib
    install_pcre
    install_openssl
    install_nghttp2
    install_apache
    #install_hexo
    config
    #delete_files
}

# Uninstall LAON
uninstall_LAON(){
    rm -rf /opt/LAON
	#cd ${hexopatch}
	#node uninstall
	#rm -rf ${hexopatch}
	#rm -rf /usr/local/n
	#rm /usr/bin/node
	rm /usr/bin/ab  /usr/bin/apachectl  /usr/bin/apxs  /usr/bin/checkgid  /usr/bin/ctlogconfig  /usr/bin/dbmmanage /usr/bin/fcgistarter  /usr/bin/firehose  /usr/bin/htcacheclean  /usr/bin/htdbm  /usr/bin/htdigest  /usr/bin/htpasswd  /usr/bin/httpd  /usr/bin/httxt2dbm  /usr/bin/logresolve  /usr/bin/rotatelogs
	#apt-get remove npm -y
	#apt-get purge npm
    echo "Uninstall Complete!"
}

# Initialization step
install_LAON
