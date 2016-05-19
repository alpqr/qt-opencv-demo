/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.3
import QtMultimedia 5.5
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import test.opencv.qt 1.0

Item {
    width : Screen.height > Screen.width ? Screen.height : Screen.width
    height : Screen.height > Screen.width ? Screen.width : Screen.height
    property string faceClassifier: appDir + "/haarcascade_frontalface_default.xml"
    property string qtClassifier: appDir + "/qtlogo.xml"

    Camera {
        id: camera
        viewfinder {
            resolution: "320x240"
            maximumFrameRate: 15
        }
    }

    MediaPlayer {
        id: media
        source: "file:" + appDir + "/qt.mp4"
    }

    function resetRects() {
        matchCount.v = 0;
        for (var i = 0; i < rectHolder.count; ++i)
            rectHolder.itemAt(i).visible = false;
    }

    CVFilter {
        id: filter
        active: cbActive.checked
        onActiveChanged: resetRects()
        property bool flip: false
        property string classifier: faceClassifier
        property real scaleFactor: slScale.value
        property int minNeighbours: slMN.value
        onFinished: {
            if (!filter.active) // due to queued slot invocations it may happen that active has changed since the emit
                return;
            var r = e.rects();
            resetRects();
            matchCount.v = r.length;
            for (var i = 0; i < r.length; ++i) {
                var xr = output.width / output.sourceRect.width;
                var yr = output.height / output.sourceRect.height;
                var rect = rectHolder.itemAt(i);
                rect.x = output.x + r[i].x * xr;
                rect.y = output.y + r[i].y * yr;
                rect.width = r[i].width * xr;
                rect.height = r[i].height * yr;
                rect.visible = true;
            }
        }
    }

    VideoOutput {
        id: output
        source: camera
        filters: [ filter ]
        anchors.fill: parent
        fillMode: VideoOutput.Stretch // the rect position calculation above needs this
    }

    Repeater {
        id: rectHolder
        model: 20
        Rectangle {
            color: "transparent"
            border.width: 4
            border.color: "red"
            visible: false
        }
    }

    Rectangle {
        height: parent.height
        width: parent.width * 0.2
        anchors.right: parent.right
        color: "white"
        opacity: 0.6

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            GroupBox {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        text: "Classifier"
                    }
                    ExclusiveGroup { id: classifierGroup }
                    RadioButton {
                        Layout.fillWidth: true
                        text: "Frontal face"
                        exclusiveGroup: classifierGroup
                        checked: true
                        onCheckedChanged: if (checked) {
                            filter.classifier = faceClassifier;
                            slScale.value = 1.3;
                            slMN.value = 5;
                        }
                    }
                    RadioButton {
                        Layout.fillWidth: true
                        text: "Qt logo"
                        exclusiveGroup: classifierGroup
                        checked: false
                        onCheckedChanged: if (checked) {
                            filter.classifier = qtClassifier;
                            slScale.value = 1.1;
                            slMN.value = 2;
                        }
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10
                    Label {
                        Layout.fillWidth: true
                        text: "Scale factor: " + Math.round(slScale.value * 10) / 10
                    }
                    Slider {
                        id: slScale
                        maximumValue: 3.0
                        minimumValue: 1.1
                        value: 1.3
                        Layout.fillWidth: true
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Min neighbours: " + slMN.value
                    }
                    Slider {
                        id: slMN
                        maximumValue: 10
                        minimumValue: 1
                        stepSize: 1
                        value: 5
                        Layout.fillWidth: true
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    Label {
                        id: matchCount
                        property int v: 0
                        text: "Found: " + v
                    }
                }
            }

            GroupBox {
                Layout.fillWidth: true
                ColumnLayout {
                    anchors.fill: parent
                    CheckBox {
                        id: cbActive
                        text: "Filtering active"
                        Layout.fillWidth: true
                        checked: true
                    }
                    CheckBox {
                        id: camSwitch
                        text: "Use camera"
                        Layout.fillWidth: true
                        checked: true
                        onCheckedChanged: {
                            resetRects();
                            if (checked) {
                                media.stop();
                                output.source = camera;
                                camera.start();
                            } else {
                                camera.stop();
                                output.source = media;
                                media.play();
                            }
                        }
                    }
                }
            }
        }
    }
}
