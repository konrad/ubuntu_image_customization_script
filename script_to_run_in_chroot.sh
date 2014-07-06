main(){
    prepare_apt
    run_apt_get
    # <Adapt to your needs>
    install_segemehl
    install_deseq
    install_reademption
    # </Adapt to your needs>
    tear_down
}

prepare_apt(){
    dbus-uuidgen > /var/lib/dbus/machine-id
    dpkg-divert --local --rename --add /sbin/initctl
    ln -s /bin/true /sbin/initctl

    echo deb http://de.archive.ubuntu.com/ubuntu/ trusty universe >> /etc/apt/sources.list
    echo deb-src http://de.archive.ubuntu.com/ubuntu/ trusty universe >> /etc/apt/sources.list
    echo deb http://de.archive.ubuntu.com/ubuntu/ trusty-updates universe >> /etc/apt/sources.list
    echo deb-src http://de.archive.ubuntu.com/ubuntu/ trusty-updates universe >> /etc/apt/sources.list
    apt-get update

}

run_apt_get(){
    apt-get install --yes python3-pip python3-matplotlib cython3 zlib1g-dev \
	make libncurses5-dev r-base libxml2-dev curl
}

install_segemehl(){
    curl http://www.bioinf.uni-leipzig.de/Software/segemehl/segemehl_0_1_9.tar.gz > segemehl_0_1_9.tar.gz
    tar xzf segemehl_0_1_9.tar.gz 
    cd segemehl_*/segemehl/ && make && cd ../../
    cp segemehl_0_1_9/segemehl/segemehl.x /usr/bin/segemehl.x
    cp segemehl_0_1_9/segemehl/lack.x /usr/bin/lack.x
    rm -rf segemehl_0_1_9*
}

install_deseq(){
    echo 'source("http://bioconductor.org/biocLite.R")' > install.R
    echo 'biocLite("DESeq2")' >> install.R
    echo 'quit(save = "no")' >> install.R
    Rscript install.R
    rm install.R
}

install_reademption(){
    pip3 install READemption
}

tear_down(){
    rm /var/lib/dbus/machine-id
    rm /sbin/initctl
    dpkg-divert --rename --remove /sbin/initctl
}

main
