Example code for Qt Multimedia video filters targeting embedded (i.MX6 devices
mainly) and desktop (Linux + OS X, Windows untested).

See http://blog.qt.io/blog/2015/03/20/introducing-video-filters-in-qt-multimedia/

This is the sample application shown on the desktop and embedded screenshots
near the end of the post.

A smaller version of the application was also built and deployed on an NXP Sabre
SD live at the QtWS2015: https://www.youtube.com/watch?v=8FRweh-Eds8

Needs qtbase, qtdeclarative, qtquickcontrols, qtmultimedia, and OpenCV 2.4.x.

To test without a camera, add a qt.mp4 video into the application's directory
and untick 'Use camera'.

Note that the filter only supports I420, NV12, and RGB frames. OpenGL textures
are supported but is readback-based and therefore slow. Therefore on platforms
that default to GL textures, try setting the QT_QUICK_NO_TEXTURE_VIDEOFRAMES
environment variable to 1.
