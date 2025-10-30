// We need to replace Java with Kotlin
// This file to add/migrate the Utility functions from Utils.java to Utils.kt

package com.opentokreactnative.utils

import com.opentok.android.BaseVideoRenderer

fun String?.toVideoScaleType(): String = when (this) {
    "fit" -> BaseVideoRenderer.STYLE_VIDEO_FIT
    "fill" -> BaseVideoRenderer.STYLE_VIDEO_FILL
    else -> BaseVideoRenderer.STYLE_VIDEO_FILL
}