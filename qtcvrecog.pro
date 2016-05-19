TEMPLATE = app

QT += quick multimedia

SOURCES = main.cpp filter.cpp opencvhelper.cpp
HEADERS = filter.h opencvhelper.h rgbframehelper.h

RESOURCES = qtcvrecog.qrc

OTHER_FILES = main.qml

!isEmpty(OPENCV_DIR) {
    INCLUDEPATH += $$OPENCV_DIR/include
    LIBS += -L $$OPENCV_DIR/lib
}

!contains(QT_CONFIG, no-pkg-config) {
    CONFIG += link_pkgconfig
    PKGCONFIG += opencv
} else {
    LIBS += -lopencv_core -lopencv_imgproc -lopencv_objdetect
}

osx {
    CONFIG -= app_bundle
    # To avoid issues with the C++ libs
    CONFIG += c++11
}

target.path = /data/user/qt/$$TARGET
dataFiles.files = *.xml
dataFiles.path = /data/user/qt/$$TARGET
INSTALLS += target dataFiles
