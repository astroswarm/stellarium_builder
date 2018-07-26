ARG ARCH

FROM astroswarm/base-$ARCH:latest

# Install X dependencies
RUN apt-get -y update && apt-get -y install \
  x11vnc \
  xvfb

# Install build dependencies
# libgl1-mesa-dev
RUN apt-get -y update && apt-get -y install build-essential cmake zlib1g-dev gcc g++ \
      graphviz doxygen gettext git \
      qtscript5-dev libqt5svg5-dev qttools5-dev-tools qttools5-dev \
      libqt5opengl5-dev qtmultimedia5-dev libqt5multimedia5-plugins \
      libqt5serialport5 libqt5serialport5-dev qtpositioning5-dev libgps-dev \
      libqt5positioning5 libqt5positioning5-plugins

# Install docker command dependencies
RUN apt-get -y update && apt-get -y install wget

# Configure application
ARG VERSION

# Build and install libdrm
#WORKDIR /tmp
#RUN apt-get install xutils-dev libpthread-stubs0-dev automake autoconf libtool
#RUN git clone git://anongit.freedesktop.org/mesa/drm
#WORKDIR /tmp/drm
#RUN ./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf
#RUN make
#RUN make install

# Build and install mesa
#WORKDIR /tmp
#RUN apt-get -y install \
#  flex bison python-mako \
#  libxcb-dri3-dev libxcb-dri2-0-dev \
#  libxcb-glx0-dev libx11-xcb-dev \
#  libxcb-present-dev libxcb-sync-dev \
#  libxshmfence-dev \
#  libxdamage-dev libxext-dev libxfixes-dev \
#  x11proto-dri2-dev x11proto-dri3-dev \
#  x11proto-present-dev x11proto-gl-dev \
#  libexpat1-dev libudev-dev gettext
#RUN git clone git://anongit.freedesktop.org/mesa/mesa
#WORKDIR /tmp/mesa
#RUN apt-get -y install libxrandr-dev
#RUN ./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf --with-gallium-drivers=vc4 --with-dri-drivers= --with-egl-platforms=x11,drm
#RUN make -j $(grep -c ^processor /proc/cpuinfo)
#RUN make -j $(grep -c ^processor /proc/cpuinfo) install

RUN apt-get -y update && apt-get -y install libgl1-mesa-dev libgl1-mesa-dri

# Build
WORKDIR /
RUN wget https://github.com/Stellarium/stellarium/releases/download/v$VERSION/stellarium-$VERSION.tar.gz
RUN gunzip stellarium-$VERSION.tar.gz
RUN tar xf stellarium-$VERSION.tar
RUN rm stellarium-$VERSION.tar
RUN mkdir -p /stellarium-$VERSION/builds/unix
WORKDIR /stellarium-$VERSION/builds/unix
RUN cmake -DCMAKE_BUILD_MODE=Release /stellarium-$VERSION
RUN make -j $(grep -c ^processor /proc/cpuinfo)
RUN make -j $(grep -c ^processor /proc/cpuinfo) install

#RUN apt-get -y install libegl1-mesa libxcb-dri2-0-dev

# Configure display
ENV BIT_DEPTH 16
ENV GUI_HEIGHT 1260
ENV GUI_WIDTH 1660

# Create startup script to run full graphical environment followed by stellarium
RUN echo "#!/usr/bin/env sh" > /start.sh
# Docker doesn't clean the file system on restart, so clean any old lock that may exist
RUN echo "/bin/rm -f /tmp/.X0-lock" >> /start.sh
RUN echo "/usr/bin/Xvfb :0 -screen 0 ${GUI_WIDTH}x${GUI_HEIGHT}x${BIT_DEPTH} &" >> /start.sh
RUN echo "/usr/bin/x11vnc -display :0 -forever &" >> /start.sh
RUN echo "DISPLAY=:0 /usr/local/bin/stellarium" >> /start.sh
RUN echo "" >> /start.sh
RUN chmod +x /start.sh

EXPOSE 5900

CMD "/start.sh"
