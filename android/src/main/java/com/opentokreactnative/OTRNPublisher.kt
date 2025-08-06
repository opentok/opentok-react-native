package com.opentokreactnative

import android.content.Context
import android.opengl.GLSurfaceView;
import android.util.AttributeSet
import android.widget.FrameLayout
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.uimanager.ReactStylesDiffMap

import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.opentok.android.BaseVideoRenderer
import com.opentok.android.OpentokError
import com.opentok.android.Publisher
import com.opentok.android.PublisherKit
import com.opentok.android.PublisherKit.PublisherListener
import com.opentok.android.Stream
import com.opentokreactnative.utils.EventUtils;
import com.opentokreactnative.utils.Utils

class OTRNPublisher : FrameLayout, PublisherListener,
    PublisherKit.AudioLevelListener,
    PublisherKit.PublisherRtcStatsReportListener,
    PublisherKit.AudioStatsListener,
    PublisherKit.MuteListener,
    PublisherKit.VideoStatsListener,
    PublisherKit.VideoListener {
    private var sessionId: String? = ""
    private var publisherId: String? = ""

    private var publisher: Publisher? = null
    private var sharedState = OTRN.getSharedState();
    private var androidOnTopMap = sharedState.getAndroidOnTopMap();
    private var androidZOrderMap = sharedState.getAndroidZOrderMap();
    private var props: MutableMap<String, Any>? = null

    constructor(context: Context) : super(context) {
        configureComponent(context)
    }

    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
        configureComponent(context)
    }

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(
        context,
        attrs,
        defStyleAttr
    ) {
        configureComponent(context)
    }

    fun updateProperties(props: ReactStylesDiffMap?) {
        if (this.props == null) {
            this.props = props?.toMap()
            return
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        publishStream(/*session ?: return*/)
    }

    private fun configureComponent(context: Context) {
        var params = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        this.setLayoutParams(params)
    }

    fun emitOpenTokEvent(name: String, payload: WritableMap) {
        val reactContext = context as ReactContext
        val surfaceId = UIManagerHelper.getSurfaceId(reactContext)
        val eventDispatcher = UIManagerHelper.getEventDispatcherForReactTag(reactContext, id)
        val event = OpenTokEvent(surfaceId, id, name, payload)
        eventDispatcher?.dispatchEvent(event)
    }

    public fun setSessionId(str: String?) {
        sessionId = str
    }

    public fun setPublisherId(str: String?) {
        publisherId = str
    }

    public fun setPublishAudio(value: Boolean) {
        publisher?.setPublishAudio(value)
    }

    public fun setPublishVideo(value: Boolean) {
        publisher?.setPublishVideo(value)
    }

    public fun setPublishCaptions(value: Boolean) {
        publisher?.setPublishCaptions(value)
    }

    public fun setAudioBitrate(value: Int) {
        // Ignore -- set as initialization option only
    }

    public fun setAudioFallbackEnabled(value: Boolean) {
        //audioFallbackEnabled = value
        //publisher?.setAudioFallbackEnabled(value)
    }

    public fun setPublisherAudioFallback(value: Boolean) {
        //publisherAudioFallback = value
    }

    public fun setSubscriberAudioFallback(value: Boolean) {
        //subscriberAudioFallback = value
    }

    public fun setCameraPosition(value: String?) {
        publisher?.cycleCamera()
    }

    public fun setCameraTorch(value: Boolean) {
        publisher?.setCameraTorch(value)
    }

    public fun setCameraZoomFactor(value: Float) {
        publisher?.setCameraZoomFactor(value)
    }

    public fun setAudioTrack(value: Boolean) {
        // Ignore -- set as initialization option only
    }

    public fun setVideoTrack(value: Boolean) {
        // Ignore -- set as initialization option only
    }

    public fun setVideoSource(value: String?) {
        // Ignore -- set as initialization option only
    }

    public fun setVideoContentHint(value: String?) {
        publisher?.getCapturer()?.setVideoContentHint(
            Utils.convertVideoContentHint(value)
        )
    }

    public fun setEnableDtx(value: Boolean) {
        // Ignore -- set as initialization option only
    }

    public fun setFrameRate(value: Int) {
        // Ignore -- set as initialization option only
    }

    public fun setName(value: String?) {
        // Ignore -- set as initialization option only
    }

    public fun setResolution(value: String?) {
        // Ignore -- set as initialization option only
    }

    public fun setScalableScreenshare(value: Boolean) {
        // Ignore -- set as initialization option only
    }

    private fun publishStream(/*session: Session*/) {
        var pubOrSub: String? = ""
        var zOrder: String? = ""
        if (this.props?.get("videoSource") == "screen") {
            publisher = Publisher.Builder(context)
                .audioBitrate((this.props?.get("audioBitrate") as Double).toInt())
                .name(this.props?.get("name") as String)
                .frameRate(
                    Publisher.CameraCaptureFrameRate.valueOf(
                        "FPS_" + (((this.props?.get("frameRate") as Double)).toInt()).toString()
                    )
                )
                .resolution(Publisher.CameraCaptureResolution.valueOf(this.props?.get("resolution") as String)) //test
                .audioTrack(this.props?.get("audioTrack") as Boolean)
                .videoTrack(this.props?.get("videoTrack") as Boolean)
                .enableOpusDtx(this.props?.get("enableDtx") as Boolean)
                .scalableScreenshare(this.props?.get("scalableScreenshare") as Boolean)
                .capturer(OTScreenCapturer(this))
                .build()
            publisher?.setPublisherVideoType(PublisherKit.PublisherKitVideoType.PublisherKitVideoTypeScreen)
        } else if (this.props?.get("videoSource") == "camera") {
            publisher = Publisher.Builder(context)
                .audioBitrate((this.props?.get("audioBitrate") as Double).toInt())
                .publisherAudioFallbackEnabled(this.props?.get("publisherAudioFallback") as Boolean)
                .subscriberAudioFallbackEnabled(this.props?.get("subscriberAudioFallback") as Boolean)
                .name(this.props?.get("name") as String)
                .frameRate(
                    Publisher.CameraCaptureFrameRate.valueOf(
                        "FPS_" + (((this.props?.get("frameRate") as Double)).toInt()).toString()
                    )
                )
                .resolution(Publisher.CameraCaptureResolution.valueOf(this.props?.get("resolution") as String)) //test
                .audioTrack(this.props?.get("audioTrack") as Boolean)
                .videoTrack(this.props?.get("videoTrack") as Boolean)
                .enableOpusDtx(this.props?.get("enableDtx") as Boolean)
                .build()
            publisher?.setPublisherVideoType(PublisherKit.PublisherKitVideoType.PublisherKitVideoTypeCamera)
            if (this.props?.get("cameraPosition") == "back") {
                publisher?.cycleCamera()
            }
            if (this.props?.get("videoTrack") as Boolean) {
                publisher?.getCapturer()?.setVideoContentHint(
                    Utils.convertVideoContentHint(this.props?.get("videoContentHint") as String)
                )
            }
        }

        publisher?.setPublishAudio(this.props?.get("publishAudio") as Boolean)
        publisher?.setPublishVideo(this.props?.get("publishVideo") as Boolean)
        publisher?.setPublishCaptions(this.props?.get("publishCaptions") as Boolean)
        publisher?.setStyle(
            BaseVideoRenderer.STYLE_VIDEO_SCALE,
            BaseVideoRenderer.STYLE_VIDEO_FILL
        )

        if (androidOnTopMap.get(sessionId) != null) {
            pubOrSub = androidOnTopMap.get(sessionId);
        }
        if (androidZOrderMap.get(sessionId) != null) {
            zOrder = androidZOrderMap.get(sessionId);
        }

        if (pubOrSub.equals("publisher") && publisher?.getView() is GLSurfaceView) {
            if (zOrder.equals("mediaOverlay")) {
                (publisher?.getView() as GLSurfaceView).setZOrderMediaOverlay(true)
            } else {
                (publisher?.getView() as GLSurfaceView).setZOrderOnTop(true)
            }
        }

        publisher?.setCameraTorch(this.props?.get("cameraTorch") as Boolean)
        publisher?.setCameraZoomFactor((this.props?.get("cameraZoomFactor") as Double).toFloat())

        //Listeners
        publisher?.setPublisherListener(this)
        publisher?.setAudioLevelListener(this)
        publisher?.setAudioStatsListener(this)
        publisher?.setMuteListener(this)
        publisher?.setVideoListener(this)
        publisher?.setVideoStatsListener(this)
        publisher?.setRtcStatsReportListener(this)

        // Move this to streamcreated? Can we get the publisherID there? or streamID is enough
        sharedState.getPublishers()
            .put(this.props?.get("publisherId") as String ?: return, publisher ?: return);
        if (publisher?.view != null) {
            this.addView(publisher?.view)
            requestLayout()
        }
        props!!.clear() //we do not need to keep this around ?
    }

    override fun onStreamCreated(publisher: PublisherKit, stream: Stream) {
        val payload = EventUtils.prepareJSStreamMap(stream, publisher.getSession())
        emitOpenTokEvent("onStreamCreated", payload)
    }

    override fun onStreamDestroyed(publisher: PublisherKit, stream: Stream) {
        val payload = EventUtils.prepareJSStreamMap(stream, publisher.getSession())
        emitOpenTokEvent("onStreamDestroyed", payload)
    }

    override fun onError(publisher: PublisherKit, opentokError: OpentokError) {
        val payload = EventUtils.prepareJSErrorMap(opentokError);
        emitOpenTokEvent("onError", payload)
    }

    override fun onAudioLevelUpdated(publisher: PublisherKit?, audioLevel: Float) {
        val publisherId = Utils.getPublisherId(publisher) // Do we need this?
        if (publisherId.isNotEmpty()) {
            val payload =
                Arguments.createMap().apply {
                    putDouble("audioLevel", audioLevel.toDouble())
                }
            emitOpenTokEvent("onAudioLevel", payload)
        }
    }

    override fun onRtcStatsReport(
        publisher: PublisherKit?,
        stats: Array<out PublisherKit.PublisherRtcStats>?
    ) {
        val statsArray: WritableArray = Arguments.createArray()
        for (stat in stats!!) {
            val rtcStats: WritableMap = Arguments.createMap()
            rtcStats.putString("connectionId", stat.connectionId)
            rtcStats.putString("jsonArrayOfReports", stat.jsonArrayOfReports)
            statsArray.pushMap(rtcStats)
        }
        val payload =
            Arguments.createMap().apply {
                putString("jsonStats", statsArray.toString())
            }
        emitOpenTokEvent("onRtcStatsReport", payload)
    }

    override fun onAudioStats(
        publisher: PublisherKit?,
        stats: Array<out PublisherKit.PublisherAudioStats>?
    ) {
        val statsArray: WritableArray = Arguments.createArray()
        for (stat in stats!!) {
            val audioStats: WritableMap = Arguments.createMap()
            audioStats.putString("connectionId", stat.connectionId)
            audioStats.putString("subscriberId", stat.subscriberId)
            audioStats.putDouble("audioPacketsLost", stat.audioPacketsLost.toDouble())
            audioStats.putDouble("audioPacketsSent", stat.audioPacketsSent.toDouble())
            audioStats.putDouble("audioBytesSent", stat.audioBytesSent.toDouble())
            audioStats.putDouble("startTime", stat.startTime)
            statsArray.pushMap(audioStats)
        }
        val payload =
            Arguments.createMap().apply {
                putString("stats", statsArray.toString())
            }
        emitOpenTokEvent("onAudioNetworkStats", payload)
    }

    override fun onMuteForced(publisher: PublisherKit?) {
        emitOpenTokEvent("onMuteForced", Arguments.createMap())
    }

    override fun onVideoStats(
        publisher: PublisherKit?,
        stats: Array<out PublisherKit.PublisherVideoStats>?
    ) {
        val publisherId = Utils.getPublisherId(publisher)
        if (publisherId.isNotEmpty()) {
            val statsArrayMap: WritableArray = Arguments.createArray()
            for (stat in stats!!) {
                val audioStats: WritableMap = Arguments.createMap()
                audioStats.putString("connectionId", stat.connectionId)
                audioStats.putString("subscriberId", stat.subscriberId)
                audioStats.putDouble("videoPacketsLost", stat.videoPacketsLost.toDouble())
                audioStats.putDouble("videoBytesSent", stat.videoBytesSent.toDouble())
                audioStats.putDouble("videoPacketsSent", stat.videoPacketsSent.toDouble())
                audioStats.putDouble("startTime", stat.startTime)
                statsArrayMap.pushMap(audioStats)
            }
            val payload =
                Arguments.createMap().apply {
                    putString("stats", statsArrayMap.toString())
                }
            emitOpenTokEvent("onVideoNetworkStats", payload)
        }
    }

    override fun onVideoDisabled(publisher: PublisherKit?, reason: String?) {
        emitOpenTokEvent("onVideoDisabled", Arguments.createMap())
    }

    override fun onVideoEnabled(publisher: PublisherKit?, reason: String?) {
        emitOpenTokEvent("onVideoEnabled", Arguments.createMap())
    }

    override fun onVideoDisableWarning(publisher: PublisherKit?) {
        emitOpenTokEvent("onVideoDisableWarning", Arguments.createMap())
    }

    override fun onVideoDisableWarningLifted(publisher: PublisherKit?) {
        emitOpenTokEvent("onVideoDisableWarningLifted", Arguments.createMap())
    }

    inner class OpenTokEvent(
        surfaceId: Int,
        viewId: Int,
        private val name: String,
        private val payload: WritableMap
    ) : Event<OpenTokEvent>(surfaceId, viewId) {
        override fun getEventName() = name
        override fun getEventData() = payload
    }
}