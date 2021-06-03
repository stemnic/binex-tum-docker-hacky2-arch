FROM archlinux:base-devel-20210523.0.23638

RUN pacman-key --init
RUN pacman -Sy --noconfirm
RUN pacman -S --noconfirm screen netcat cmake wget gdb htop vim git tmux pwndbg svn gd lib32-gcc-libs patch make bison fakeroot python-pip


RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
    ENV LANG en_US.UTF-8  
    ENV LANGUAGE en_US:en  
    ENV LC_ALL en_US.UTF-8 


# https://ftp.gnu.org/gnu/glibc/glibc-2.33.tar.xz
RUN mkdir /usr/src/glibc
RUN cd /usr/src/glibc \
    && wget https://ftp.gnu.org/gnu/glibc/glibc-2.33.tar.xz\ 
    && tar xvf glibc-2.33.tar.xz


RUN useradd -M build
RUN mkdir packages && chown -R build:build /packages && chmod -R 777 /packages
USER build

RUN cd packages \
    && git clone https://aur.archlinux.org/ncurses5-compat-libs.git \
    && cd ncurses5-compat-libs \
    && makepkg --skipchecksums --skippgpcheck
    # Install glibc-debug \

USER root
RUN cd /packages/ncurses5-compat-libs \
    && ls -la \
    && pacman -U --noconfirm *.pkg.tar.zst


#RUN useradd -M build
#RUN mkdir packages && chown -R build:build /packages
#USER build
# glibc debug symbols on Arch Linux (not working now for some reason)
#RUN svn checkout --depth=empty svn://svn.archlinux.org/packages \
#    && cd packages \
#    && svn update glibc \
#    && cd glibc/repos/core-x86_64 \
#    # Add current locale to locale.gen.txt \
#    && grep -v "#" /etc/locale.gen >> locale.gen.txt \
#    # Enable debug build in PKGBUILD \
#    && sed -i 's#!strip#debug#' PKGBUILD \
#    && cat PKGBUILD \
#    # Build glibc and glibc-debug packages \
#    && makepkg --skipchecksums --skippgpcheck
#    # Install glibc-debug \
#
#USER root
#RUN cd packages/glibc/repos/core-x86_64 \
#    && pacman -U --noconfirm *.pkg.tar.xz
#    #&& sed '/^OPTIONS/ s/!debug/debug/g; /^OPTIONS/ s/strip/!strip/g' /etc/makepkg.conf

# Pwntools
RUN python -m pip install --upgrade pip \
    && python -m pip install --upgrade pwntools

RUN echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
RUN echo "export PYTHONIOENCODING=UTF-8" >> ~/.bashrc

# Angr for symbolic execution
RUN python -m pip install --upgrade angr

RUN echo "source /usr/share/pwndbg/gdbinit.py" >> ~/.gdbinit
RUN echo "dir /usr/src/glibc/glibc-2.33/malloc/" >> ~/.gdbinit

# ynet daemon
ADD https://yx7.cc/code/ynetd/ynetd-0.1.2.tar.xz /ynetd-0.1.2.tar.xz
RUN tar -xf ynetd-0.1.2.tar.xz
RUN make -C /ynetd-0.1.2/
RUN useradd -m pwn

#ADD vuln /home/pwn/vuln
ADD start_server.sh /usr/local/bin/
ADD init.sh /usr/local/bin/
ADD banner /root/.banner
RUN chmod +x /usr/local/bin/start_server.sh
RUN chmod +x /usr/local/bin/init.sh
RUN echo 'export PS1="\n\[\e[01;33m\]\u\[\e[0m\]\[\e[00;37m\]@\[\e[0m\]\[\e[01;36m\]\h\[\e[0m\]\[\e[00;37m\] \[\e[0m\]\[\e[01;35m\]\w\[\e[0m\]\[\e[01;37m\] \[\e[0m\]\n$ "' >> ~/.bashrc
#RUN chmod 0755 /home/pwn/vuln

EXPOSE 1337

WORKDIR /home/pwn/

CMD ["/usr/local/bin/init.sh"]
