package com.opentokreactnative

import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.widget.FrameLayout;
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.ReactContext
import com.facebook.react.uimanager.ReactStylesDiffMap
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.Event
import com.opentok.android.BaseVideoRenderer
import com.opentok.android.OpentokError
import com.opentok.android.Session
import com.opentok.android.Stream
import com.opentok.android.Subscriber
import com.opentok.android.SubscriberKit
import com.opentok.android.SubscriberKit.SubscriberListener
import com.opentok.android.SubscriberKit.SubscriberRtcStatsReportListener
import com.opentok.android.VideoUtils
import kotlin.collections.component1
import kotlin.collections.component2
import kotlin.collections.iterator

class OTSubscriberViewNative : FrameLayout, SubscriberListener,
    SubscriberRtcStatsReportListener, SubscriberKit.AudioLevelListener,
    SubscriberKit.CaptionsListener,
    SubscriberKit.AudioStatsListener,
    SubscriberKit.VideoStatsListener,
    SubscriberKit.VideoListener,
    SubscriberKit.StreamListener {
    private var session: Session? = null
    private var stream: Stream? = null
    private var sessionId: String? = ""
    private var streamId: String? = ""
    //private var subscribeToAudio = true
    //private var subscribeToVideo = true
    private var subscriber: Subscriber? = null
    private var sharedState = OTRN.getSharedState();
    private var TAG = this.javaClass.simpleName
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
            for ((key, value) in this.props?.toMap() ?: emptyMap()) {
                Log.d(TAG, "updateProperties: $key $value")
            }
        }
    }

    override fun onAttachedToWindow() {
        session = sharedState.getSessions().get(sessionId)
        stream = sharedState.getSubscriberStreams().get(streamId)
        super.onAttachedToWindow()
        subscribeToStream(session ?: return, stream ?: return)
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

    public fun setSubscribeToAudio(value: Boolean) {
        //subscribeToAudio = value
        subscriber?.subscribeToAudio = value
    }

    public fun setSubscribeToVideo(value: Boolean) {
        //subscribeToVideo = value
        subscriber?.subscribeToVideo = value
    }

    public fun setStreamId(str: String?) {
        streamId = str
    }

    fun setSubscribeToCaptions(value: Boolean) {
        subscriber?.subscribeToCaptions = value
    }

    fun setAudioVolume(value: Double) {
        subscriber?.audioVolume = value
    }

    fun setPreferredFrameRate(value: Int) {
        subscriber?.preferredFrameRate = value.toFloat()
    }

    fun setPreferredResolution(value: String?) {
        var values: List<String> = value?.split("x") ?: return
        var width: Int = values[0].toInt()
        var height: Int = values[1].toInt()
        subscriber?.setPreferredResolution(VideoUtils.Size(width, height))
    }

    fun subscribeToStream(session: Session, stream: Stream) {
        Log.d(TAG, "subscribeToStream: " + stream.streamId)
        subscriber = Subscriber.Builder(context, stream)
            .build()
        sharedState.getSubscribers().put(stream.getStreamId(), subscriber ?: return);
        subscriber?.setStyle(
            BaseVideoRenderer.STYLE_VIDEO_SCALE,
            BaseVideoRenderer.STYLE_VIDEO_FILL
        )
        subscriber?.setSubscriberListener(this)
        subscriber?.setRtcStatsReportListener(this)
        subscriber?.setCaptionsListener(this)
        subscriber?.setAudioStatsListener(this)
        subscriber?.setVideoStatsListener(this)
        subscriber?.setVideoListener(this)
        subscriber?.setStreamListener(this)
        subscriber?.setAudioLevelListener(this)

        subscriber?.setSubscribeToAudio(this.props?.get("subscribeToAudio") as Boolean)
        subscriber?.setSubscribeToVideo(this.props?.get("subscribeToVideo") as Boolean)
        if (this.props?.get("subscribeToCaptions") != null) {
            subscriber?.setSubscribeToCaptions(this.props?.get("subscribeToCaptions") as Boolean)
        }
        if (this.props?.get("audioVolume") != null) {
            subscriber?.setAudioVolume(this.props?.get("audioVolume") as Double)
        }
        if (this.props?.get("preferredFrameRate") != null) {
            subscriber?.setPreferredFrameRate(this.props?.get("preferredFrameRate") as Float)
        }
        if (this.props?.get("preferredResolution") != null) {
            var res : String = this.props?.get("preferredResolution") as String
            var values: List<String> = res.split("x")
            var width: Int = values[0].toInt()
            var height: Int = values[1].toInt()
            subscriber?.setPreferredResolution(VideoUtils.Size(width, height))
        }

        //clear the props map here..
        this.props?.clear()

        session.subscribe(subscriber)
        if (subscriber?.view != null) {
            this.addView(subscriber?.view)
            requestLayout()
        }
    }

    override fun onConnected(subscriber: SubscriberKit) {
        Log.d(TAG, "onConnected: " + subscriber.stream.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", stream!!.streamId)
            }
        emitOpenTokEvent("onSubscriberConnected", payload)
        // TODO ("Do we need to add to sharedState")

    }

    override fun onDisconnected(subscriber: SubscriberKit) {
        Log.d(TAG, "onDisconnected: " + subscriber.stream.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber.getStream().streamId)
            }
        emitOpenTokEvent("onSubscriberDisconnected", payload)
        // TODO ("Do we need to remove from sharedState")
    }

    override fun onError(subscriber: SubscriberKit, opentokError: OpentokError) {
        Log.d(TAG, "onError: " + subscriber.getStream().streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber.getStream().streamId)
                putString("errorMessage", opentokError.message)
            }
        emitOpenTokEvent("onSubscriberError", payload)
    }

    override fun onRtcStatsReport(subscriber: SubscriberKit, jsonArrayOfReports: String) {
        Log.d(TAG, "onRtcStatsReport: " + subscriber.getStream().streamId)
        val payload =
            Arguments.createMap().apply {
                putString("jsonArrayOfReports", jsonArrayOfReports)
            }
        emitOpenTokEvent("onRtcStatsReport", payload)
    }

    override fun onAudioLevelUpdated(subscriber: SubscriberKit?, audioLevel: Float) {
        Log.d(TAG, "onAudioLevelUpdated: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putDouble("audioLevel", audioLevel.toDouble())
            }
        emitOpenTokEvent("onAudioLevel", payload)
    }

    override fun onCaptionText(subscriber: SubscriberKit?, text: String?, isFinal: Boolean) {
        Log.d(TAG, "onCaptionText: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("text", text);
                putBoolean("isFinal", isFinal);
            }
        emitOpenTokEvent("onCaptionReceived", payload)
    }

    override fun onAudioStats(
        subscriber: SubscriberKit?,
        stats: SubscriberKit.SubscriberAudioStats?
    ) {
        Log.d(TAG, "onAudioStats: " + subscriber?.getStream()?.streamId)
        val audioStats: WritableMap = Arguments.createMap()
        audioStats.putDouble("audioPacketsLost", stats?.audioPacketsLost?.toDouble() ?: 0.0)
        audioStats.putDouble("audioPacketsReceived", stats?.audioPacketsReceived?.toDouble() ?: 0.0)
        audioStats.putDouble("audioBytesReceived", stats?.audioBytesReceived?.toDouble() ?: 0.0)
        audioStats.putDouble("startTime", stats?.timeStamp?.toDouble() ?: 0.0)
        emitOpenTokEvent("onAudioStats", audioStats)
    }

    override fun onVideoStats(
        subscriber: SubscriberKit?,
        stats: SubscriberKit.SubscriberVideoStats?
    ) {
        Log.d(TAG, "onVideoStats: " + subscriber?.getStream()?.streamId)
        val videoStats: WritableMap = Arguments.createMap()
        videoStats.putDouble("videoPacketsLost", stats?.videoPacketsLost?.toDouble() ?: 0.0)
        videoStats.putDouble("videoPacketsReceived", stats?.videoPacketsReceived?.toDouble() ?: 0.0)
        videoStats.putDouble("videoBytesReceived", stats?.videoBytesReceived?.toDouble() ?: 0.0)
        videoStats.putDouble("startTime", stats?.timeStamp?.toDouble() ?: 0.0)
        Log.d(TAG, "onVideoStats: " + videoStats.toString())
        emitOpenTokEvent("onVideoNetworkStats", videoStats)
    }

    override fun onVideoDataReceived(subscriber: SubscriberKit?) {
        Log.d(TAG, "onVideoDataReceived: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
            }
        emitOpenTokEvent("onVideoDataReceived", payload)
    }

    override fun onVideoDisabled(subscriber: SubscriberKit?, reason: String?) {
        Log.d(TAG, "onVideoDisabled: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
                putString("reason", reason)
            }
        emitOpenTokEvent("onVideoDisabled", payload)
    }

    override fun onVideoEnabled(subscriber: SubscriberKit?, reason: String?) {
        Log.d(TAG, "onVideoEnabled: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
                putString("reason", reason)
            }
        emitOpenTokEvent("onVideoEnabled", payload)
    }

    override fun onVideoDisableWarning(subscriber: SubscriberKit?) {
        Log.d(TAG, "onVideoDisableWarning: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
            }
        emitOpenTokEvent("onVideoDisableWarning", payload)
    }

    override fun onVideoDisableWarningLifted(subscriber: SubscriberKit?) {
        Log.d(TAG, "onVideoDisableWarningLifted: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
            }
        emitOpenTokEvent("onVideoDisableWarningLifted", payload)
    }

    override fun onReconnected(subscriber: SubscriberKit?) {
        Log.d(TAG, "onReconnected: " + subscriber?.getStream()?.streamId)
        val payload =
            Arguments.createMap().apply {
                putString("streamId", subscriber?.getStream()?.streamId)
            }
        emitOpenTokEvent("onReconnected", payload)
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