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

#include "filter.h"
#include "opencvhelper.h"
#include "rgbframehelper.h"
#include <QFile>

QVideoFilterRunnable *Filter::createFilterRunnable()
{
    return new FilterRunnable(this);
}

FilterRunnable::FilterRunnable(Filter *filter)
    : m_filter(filter),
      m_classifier(0)
{
}

QVideoFrame FilterRunnable::run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags)
{
    Q_UNUSED(surfaceFormat);
    Q_UNUSED(flags);

    // Supports YUV (I420 and NV12) and RGB. The GL path is readback-based and slow.
    if (!input->isValid()
            || (input->handleType() != QAbstractVideoBuffer::NoHandle && input->handleType() != QAbstractVideoBuffer::GLTextureHandle)) {
        qWarning("Invalid input format");
        return QVideoFrame();
    }

    input->map(QAbstractVideoBuffer::ReadOnly);
    if (input->pixelFormat() == QVideoFrame::Format_YUV420P || input->pixelFormat() == QVideoFrame::Format_NV12) {
        m_yuv = true;
        m_mat = yuvFrameToMat8(*input);
    } else {
        m_yuv = false;
        QImage wrapper = imageWrapper(*input);
        if (wrapper.isNull()) {
            if (input->handleType() == QAbstractVideoBuffer::NoHandle)
                input->unmap();
            return *input;
        }
        m_mat = imageToMat8(wrapper);
    }
    ensureC3(&m_mat);
    if (input->handleType() == QAbstractVideoBuffer::NoHandle)
        input->unmap();

    // 1. Convert to grayscale
    cvtColor(m_mat, m_mat, CV_BGR2GRAY);

    // 2. Flip if requested
    if (m_filter->property("flip").toBool())
        cv::flip(m_mat, m_mat, -1);

    // 3. Detect
    FilterResult *r = new FilterResult;

    QByteArray filename = m_filter->property("classifier").toString().toUtf8();
    if (filename != m_prevName) {
        delete m_classifier;
        m_classifier = 0;
        m_prevName = filename;
    }

    if (!filename.isEmpty()) {
        if (!m_classifier) {
            if (!QFile::exists(filename))
                qWarning("Classifier does not exist: %s", qPrintable(filename));
            m_classifier = new cv::CascadeClassifier(filename.constData());
        }

        std::vector<cv::Rect> rects;
        float scaleFactor = qBound(1.1f, m_filter->property("scaleFactor").toFloat(), 5.0f);
        int minNeighbours = qBound(1, m_filter->property("minNeighbours").toInt(), 20);
        m_classifier->detectMultiScale(m_mat, rects, scaleFactor, minNeighbours, CV_HAAR_SCALE_IMAGE);

        for (size_t i = 0; i < rects.size(); ++i)
            r->m_rects.append(QRect(rects[i].x, rects[i].y, rects[i].width, rects[i].height));
    }

    if (m_mat.type() == CV_8UC1)
        cvtColor(m_mat, m_mat, CV_GRAY2BGR);

    emit m_filter->finished(r);

    // Output is an RGB video frame.
    return QVideoFrame(mat8ToImage(m_mat));
}
