/****************************************************************************
**
** Copyright (C) 2015 Digia Plc
** All rights reserved.
** For any questions to Digia, please use contact form at http://www.qt.io
**
** This file is part of QtEnterprise Embedded.
**
** Licensees holding valid Qt Enterprise licenses may use this file in
** accordance with the Qt Enterprise License Agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and Digia.
**
** If you have questions regarding the use of this file, please use
** contact form at http://www.qt.io
**
****************************************************************************/

#ifndef OPENCVHELPER_H
#define OPENCVHELPER_H

#include <opencv2/imgproc/imgproc.hpp>
#include <QtGui/QImage>
#include <QtMultimedia/QVideoFrame>

// QImage -> CV_8UC4
cv::Mat imageToMat8(const QImage &image);

// CV_8UC3|4 -> CV_8UC3
void ensureC3(cv::Mat *mat);

// CV_8UC1|3|4 -> QImage
QImage mat8ToImage(const cv::Mat &mat);

// YUV QVideoFrame -> CV_8UC3
cv::Mat yuvFrameToMat8(const QVideoFrame &frame);

// CV_8UC3|4 -> YUV QVideoFrame
QVideoFrame mat8ToYuvFrame(const cv::Mat &mat);

// CV_8UC3|4 -> YUV pre-alloced mem
void mat8ToYuvFrame(const cv::Mat &mat, uchar *dst);

#endif
