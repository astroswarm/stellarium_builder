ARG ARCH

FROM astroswarm/base-$ARCH:latest

# Install X dependencies
RUN apt-get -y update && apt-get -y install \
  x11vnc \
  xvfb

# Install build dependencies
RUN apt-get -y update && apt-get -y install build-essential cmake zlib1g-dev libgl1-mesa-dev gcc g++ \
      graphviz doxygen gettext git \
      qtscript5-dev libqt5svg5-dev qttools5-dev-tools qttools5-dev \
      libqt5opengl5-dev qtmultimedia5-dev libqt5multimedia5-plugins \
      libqt5serialport5 libqt5serialport5-dev qtpositioning5-dev libgps-dev \
      libqt5positioning5 libqt5positioning5-plugins

# Install docker command dependencies
RUN apt-get -y update && apt-get -y install wget

# Configure application
ARG VERSION

# Build
RUN wget https://github.com/Stellarium/stellarium/releases/download/v$VERSION/stellarium-$VERSION.tar.gz
RUN gunzip stellarium-$VERSION.tar.gz
RUN tar xf stellarium-$VERSION.tar
RUN rm stellarium-$VERSION.tar
RUN mkdir -p /stellarium-$VERSION/builds/unix
WORKDIR /stellarium-$VERSION/builds/unix
RUN cmake -DCMAKE_BUILD_MODE=Release /stellarium-$VERSION
RUN make -j $(grep -c ^processor /proc/cpuinfo)
RUN make -j $(grep -c ^processor /proc/cpuinfo) install

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
RUN echo "DISPLAY=:0 /usr/local/stellarium" >> /start.sh
RUN echo "" >> /start.sh
RUN chmod +x /start.sh

EXPOSE 5900

CMD "/start.sh"
