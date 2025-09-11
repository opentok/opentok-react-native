package com.opentokreactnative

import android.content.Context
import android.opengl.GLSurfaceView;
import android.util.AttributeSet
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
import com.opentokreactnative.utils.EventUtils;
import kotlin.collections.component1
import kotlin.collections.component2
import kotlin.collections.iterator

class OTRNSubscriber : FrameLayout, SubscriberListener,
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
    private var subscriber: Subscriber? = null
    private var sharedState = OTRN.getSharedState();
    private var TAG = this.javaClass.simpleName
    private var androidOnTopMap = sharedState.getAndroidOnTopMap();
    private var androidZOrderMap = sharedState.getAndroidZOrderMap();
    private var props: MutableMap<String, Any>? = null

    constructor(context: Context) : super(context) {
        configureComponent()
    }

    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
        configureComponent()
    }

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(
        context,
        attrs,
        defStyleAttr
    ) {
        configureComponent()
    }

    fun updateProperties(props: ReactStylesDiffMap?) {
        if (this.props == null) {
            this.props = props?.toMap()
        }
    }

    override fun onAttachedToWindow() {
        session = sharedState.getSessions().get(sessionId)
        stream = sharedState.getSubscriberStreams().get(streamId)
        super.onAttachedToWindow()
        subscribeToStream(session ?: return, stream ?: return)
    }

    private fun configureComponent() {
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
        subscriber?.subscribeToAudio = value
    }

    public fun setSubscribeToVideo(value: Boolean) {
        subscriber?.subscribeToVideo = value
    }

    public fun setStreamId(str: String?) {
        streamId = str
    }

    fun setSubscribeToCaptions(value: Boolean) {
        subscriber?.subscribeToCaptions = value
    }

    fun setAudioVolume(value: Float) {
        subscriber?.audioVolume = value.toDouble()
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
        var pubOrSub: String? = ""
        var zOrder: String? = ""
        subscriber = Subscriber.Builder(context, stream)
            .build()
        sharedState.getSubscribers().put(stream.getStreamId(), subscriber ?: return);
        subscriber?.setStyle(
            BaseVideoRenderer.STYLE_VIDEO_SCALE,
            BaseVideoRenderer.STYLE_VIDEO_FILL
        )

        if (androidOnTopMap.get(sessionId) != null) {
            pubOrSub = androidOnTopMap.get(sessionId);
        }
        if (androidZOrderMap.get(sessionId) != null) {
            zOrder = androidZOrderMap.get(sessionId);
        }

        if (pubOrSub.equals("subscriber") && subscriber?.getView() is GLSurfaceView) {
            if (zOrder.equals("mediaOverlay")) {
                (subscriber?.getView() as GLSurfaceView).setZOrderMediaOverlay(true)
            } else {
                (subscriber?.getView() as GLSurfaceView).setZOrderOnTop(true)
            }
        }

        subscriber?.setSubscriberListener(this)
        subscriber?.setRtcStatsReportListener(this)
        subscriber?.setCaptionsListener(this)
        subscriber?.setAudioStatsListener(this)
        subscriber?.setVideoStatsListener(this)
        subscriber?.setVideoListener(this)
        subscriber?.setStreamListener(this)
        subscriber?.setAudioLevelListener(this)

        if (this.props?.get("subscribeToAudio") != null) {
            subscriber?.setSubscribeToAudio(this.props?.get("subscribeToAudio") as Boolean)
        }
        if (this.props?.get("subscribeToVideo") != null) {
            subscriber?.setSubscribeToVideo(this.props?.get("subscribeToVideo") as Boolean)
        }
        if (this.props?.get("subscribeToCaptions") != null) {
            subscriber?.setSubscribeToCaptions(this.props?.get("subscribeToCaptions") as Boolean)
        }
        if (this.props?.get("audioVolume") != null) {
            subscriber?.setAudioVolume(this.props?.get("audioVolume") as Double)
        }
        if (this.props?.get("preferredFrameRate") != null) {
            subscriber?.setPreferredFrameRate((this.props?.get("preferredFrameRate") as Double).toFloat())
        }
        if (this.props?.get("preferredResolution") != null) {
            var res : String = this.props?.get("preferredResolution") as String
            var values: List<String> = res.split("x")
            var width: Int = values[0].toInt()
            var height: Int = values[1].toInt()
            subscriber?.setPreferredResolution(VideoUtils.Size(width, height))
        }

        this.props?.clear()

        session.subscribe(subscriber)
        if (subscriber?.view != null) {
            this.addView(subscriber?.view)
            requestLayout()
        }
    }

    override fun onConnected(subscriber: SubscriberKit) {
        val stream = EventUtils.prepareJSStreamMap(subscriber.getStream(), subscriber.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
            }
        emitOpenTokEvent("onSubscriberConnected", payload)
    }

    override fun onDisconnected(subscriber: SubscriberKit) {
        val stream = EventUtils.prepareJSStreamMap(subscriber.getStream(), subscriber.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
            }
        emitOpenTokEvent("onSubscriberDisconnected", payload)
    }

    override fun onError(subscriber: SubscriberKit, opentokError: OpentokError) {
        val stream = EventUtils.prepareJSStreamMap(subscriber.getStream(), subscriber.getSession())
        val error = EventUtils.prepareJSErrorMap(opentokError)
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
                putMap("error", error)
            }
        emitOpenTokEvent("onSubscriberError", payload)
    }

    override fun onRtcStatsReport(subscriber: SubscriberKit, jsonArrayOfReports: String) {
        val stream = EventUtils.prepareJSStreamMap(subscriber.getStream(), subscriber.getSession())
        val payload =
            Arguments.createMap().apply {
                putString("jsonArrayOfReports", jsonArrayOfReports)
                putMap("stream", stream)
            }
        emitOpenTokEvent("onRtcStatsReport", payload)
    }

    override fun onAudioLevelUpdated(subscriber: SubscriberKit?, audioLevel: Float) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putDouble("audioLevel", audioLevel.toDouble())
                putMap("stream", stream)
            }
        emitOpenTokEvent("onAudioLevel", payload)
    }

    override fun onCaptionText(subscriber: SubscriberKit?, text: String?, isFinal: Boolean) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putString("text", text)
                putBoolean("isFinal", isFinal)
                putMap("stream", stream)
            }
        emitOpenTokEvent("onCaptionReceived", payload)
    }

    override fun onAudioStats(
        subscriber: SubscriberKit?,
        stats: SubscriberKit.SubscriberAudioStats?
    ) {
        val audioStats: WritableMap = Arguments.createMap()
        audioStats.putDouble("audioPacketsLost", stats?.audioPacketsLost?.toDouble() ?: 0.0)
        audioStats.putDouble("audioPacketsReceived", stats?.audioPacketsReceived?.toDouble() ?: 0.0)
        audioStats.putDouble("audioBytesReceived", stats?.audioBytesReceived?.toDouble() ?: 0.0)
        audioStats.putDouble("startTime", stats?.timeStamp?.toDouble() ?: 0.0)
        emitOpenTokEvent("onAudioNetworkStats", audioStats)
    }

    override fun onVideoStats(
        subscriber: SubscriberKit?,
        stats: SubscriberKit.SubscriberVideoStats?
    ) {
        val videoStats: WritableMap = Arguments.createMap()
        videoStats.putDouble("videoPacketsLost", stats?.videoPacketsLost?.toDouble() ?: 0.0)
        videoStats.putDouble("videoPacketsReceived", stats?.videoPacketsReceived?.toDouble() ?: 0.0)
        videoStats.putDouble("videoBytesReceived", stats?.videoBytesReceived?.toDouble() ?: 0.0)
        videoStats.putDouble("startTime", stats?.timeStamp?.toDouble() ?: 0.0)
        emitOpenTokEvent("onVideoNetworkStats", videoStats)
    }

    override fun onVideoDataReceived(subscriber: SubscriberKit?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
            }
        emitOpenTokEvent("onVideoDataReceived", payload)
    }

    override fun onVideoDisabled(subscriber: SubscriberKit?, reason: String?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
                putString("reason", reason)
            }
        emitOpenTokEvent("onVideoDisabled", payload)
    }

    override fun onVideoEnabled(subscriber: SubscriberKit?, reason: String?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
                putString("reason", reason)
            }
        emitOpenTokEvent("onVideoEnabled", payload)
    }

    override fun onVideoDisableWarning(subscriber: SubscriberKit?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
            }
        emitOpenTokEvent("onVideoDisableWarning", payload)
    }

    override fun onVideoDisableWarningLifted(subscriber: SubscriberKit?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
            }
        emitOpenTokEvent("onVideoDisableWarningLifted", payload)
    }

    override fun onReconnected(subscriber: SubscriberKit?) {
        val stream = EventUtils.prepareJSStreamMap(subscriber?.getStream(), subscriber?.getSession())
        val payload =
            Arguments.createMap().apply {
                putMap("stream", stream)
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