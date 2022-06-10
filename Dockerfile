FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# INSTALL SOURCES FOR CHROME REMOTE DESKTOP AND VSCODE
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get --assume-yes install curl gpg wget
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | \
   tee /etc/apt/sources.list.d/vs-code.list
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get install --assume-yes --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable psmisc python3-psutil
# INSTALL OTHER SOFTWARE (I.E VSCODE)
RUN apt-get install --assume-yes --fix-missing code 
# INSTALL REMOTE DESKTOP
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg --install chrome-remote-desktop_current_amd64.deb
RUN apt-get install --assume-yes --fix-broken
RUN bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
# ---------------------------------------------------------- 
# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=myuser
ARG PIN=271828
ARG CODE=4/1AY2e-g4KM-JyQgALDqxIcTTO8ZGcHt-0FJb_wJACFZ_SVJdFNAzU6_qoQv_vEAcENw-sww
ARG HOSTNAME=myvirtualdesktop
# ---------------------------------------------------------- 
# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER
RUN mkhomedir_helper $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -aG chrome-remote-desktop $USER
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop
RUN chown "$USER:$USER" .config/chrome-remote-desktop
RUN chmod a+rx .config/chrome-remote-desktop
RUN touch .config/chrome-remote-desktop/host.json
# INSTALL GOOGLE'S CHROME REMOTE DESKTOP WITH CODE, HOSTNAME AND PIN FROM ENV VAR
RUN DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE \
    --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN
# COPY THE CONFIGURATION TO THE NEW FILE THAT MATCHES THE CORRECT HOSTNAME (MD5 HASH THEREOF)
RUN HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
    FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
    cp .config/chrome-remote-desktop/host#*.json $FILENAME
RUN sudo service chrome-remote-desktop stop
# EXTEND THE CMD WITH SLEEP INFINITY & WAIT IN ORDER TO KEEP THE REMOTE DESKTOP RUNNING
CMD [ "/bin/bash","-c","sudo service chrome-remote-desktop start ; echo $HOSTNAME ; sleep infinity & wait"]