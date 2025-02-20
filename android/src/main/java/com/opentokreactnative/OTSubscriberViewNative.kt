package com.opentokreactnative

import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.widget.FrameLayout;
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.ReactContext
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

class OTSubscriberViewNative: FrameLayout, SubscriberListener, SubscriberRtcStatsReportListener {
  private var session: Session? = null
  private var stream: Stream? = null
  private var sessionId: String?= ""
  private var streamId: String?= ""
  private var subscribeToAudio = true
  private var subscribeToVideo = true
  private var subscriber: Subscriber? = null
  private var sharedState = OTRN.getSharedState();

  constructor(context: Context) : super(context) {
    configureComponent(context)
  }

  constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
    configureComponent(context)
  }

  constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {
    configureComponent(context)
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
    // this.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
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
    subscribeToAudio = value
    subscriber?.setSubscribeToAudio(value)
  }

  public fun setSubscribeToVideo(value: Boolean) {
    subscribeToVideo = value
    subscriber?.setSubscribeToVideo(value)
  }

  public fun setStreamId(str: String?) {
    streamId = str
  }

  fun subscribeToStream(session: Session, stream: Stream) {
    subscriber = Subscriber.Builder(context, stream).build()
    sharedState.getSubscribers().put(stream.getStreamId(), subscriber?: return);
    subscriber?.setStyle(
        BaseVideoRenderer.STYLE_VIDEO_SCALE,
        BaseVideoRenderer.STYLE_VIDEO_FILL
    )
    subscriber?.setSubscriberListener(this)
    subscriber?.setRtcStatsReportListener(this)
    subscriber?.setSubscribeToAudio(subscribeToAudio)
    subscriber?.setSubscribeToVideo(subscribeToVideo)
    // FrameLayout mubscriberViewContainer = FrameLayout(context);

    session.subscribe(subscriber)
    if (subscriber?.view != null) {
      subscriber?.view?.layoutParams = LayoutParams(1000, 1000)
      this.addView(subscriber?.view)
      requestLayout()
      val subscriberView = subscriber?.view
      if (subscriberView != null) {
        subscriberView.measure(
          View.MeasureSpec.makeMeasureSpec(subscriberView.getMeasuredWidth(), View.MeasureSpec.EXACTLY),
          View.MeasureSpec.makeMeasureSpec(subscriberView.getMeasuredHeight(), View.MeasureSpec.EXACTLY));
        subscriberView.layout(subscriberView.getLeft(), subscriberView.getTop(), 640, 480)
        // subscriberView.layout(subscriberView.getLeft(), subscriberView.getTop(), subscriberView.getRight(), subscriberView.getBottom())
      }
    }
  }


  override fun onConnected(subscriber: SubscriberKit) {
      val payload =
        Arguments.createMap().apply {
          putString("streamId", stream!!.streamId)
        }
      emitOpenTokEvent("onSubscriberConnected", payload)
  }

  override fun onDisconnected(subscriber: SubscriberKit) {
    /*
      val payload =
        Arguments.createMap().apply {
          putString("streamId", subscriber.getStream().streamId)
        }
      emitOpenTokEvent("onSubscriberDisconnected", payload)
    */
  }

  override fun onError(subscriber: SubscriberKit, opentokError: OpentokError) {
    /*
      val payload =
        Arguments.createMap().apply {
          putString("streamId", subscriber.getStream().streamId)
          putString("errorMessage", opentokError.message)
        }
      emitOpenTokEvent("onSubscriberError", payload)
    */
  }

  override fun onRtcStatsReport(subscriber: SubscriberKit, jsonArrayOfReports: String) {
      val payload =
        Arguments.createMap().apply {
          putString("jsonArrayOfReports", jsonArrayOfReports)
        }
      emitOpenTokEvent("onRtcStatsReport", payload)
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