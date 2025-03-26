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
import com.opentok.android.Publisher
import com.opentok.android.PublisherKit
import com.opentok.android.PublisherKit.PublisherListener
// import com.opentok.android.PublisherKit.PublisherRtcStatsReportListener

class OTPublisherViewNative: FrameLayout, PublisherListener,
  PublisherKit.AudioLevelListener,
  PublisherKit.PublisherRtcStatsReportListener,
  PublisherKit.AudioStatsListener,
  PublisherKit.MuteListener,
  PublisherKit.VideoStatsListener,
  PublisherKit.VideoListener {
  private var session: Session? = null
  private var sessionId: String?= ""
  private var publisherId: String?= ""
  private var publishAudio = true
  private var publishVideo = true
  private var publishCaptions = false
  private var audioBitRate = 40000
  private var audioFallbackEnabled = true
  private var subscriberAudioFallback = true
  private var publisherAudioFallback = true
  private var publisher: Publisher? = null
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
    super.onAttachedToWindow()
    publishStream(session ?: return)
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

  public fun setPublisherId(str: String?) {
    publisherId = str
  }

  public fun setPublishAudio(value: Boolean) {
    publishAudio = value
    publisher?.setPublishAudio(value)
  }

  public fun setPublishCaptions(value: Boolean) {
    publishCaptions = value
    publisher?.setPublishCaptions(value)
  }

  public fun setPublishVideo(value: Boolean) {
    publishVideo = value
    publisher?.setPublishVideo(value)
  }

  public fun setAudioBitrate(value: Int) {
    audioBitRate = value
  }

  public fun setAudioFallbackEnabled(value: Boolean) {
    audioFallbackEnabled = value
    publisher?.setAudioFallbackEnabled(value)
  }

  public fun setPublisherAudioFallback(value: Boolean) {
    publisherAudioFallback = value
  }

  public fun setSubscriberAudioFallback(value: Boolean) {
    subscriberAudioFallback = value
  }

  public fun setCameraPosition(value: String?) {
    // TODO
  }

  public fun setAudioTrack(value: Boolean) {
    // TODO
  }

  public fun setVideoTrack(value: Boolean) {
    // TODO
  }

  public fun setVideoSource(value: String?) {
    // TODO
  }

  public fun setVideoContentHint(value: String?) {
    // TODO
  }

  public fun setEnableDtx(value: Boolean) {
    // TODO
  }

  public fun setFrameRate(value: Int) {
    // TODO
  }

  public fun setName(value: String?) {
    // TODO
  }

  public fun setResolution(value: String?) {
    // TODO
  }

  public fun setScalableScreenshare(value: Boolean) {
    // TODO
  }

  fun publishStream(session: Session) {
    publisher = Publisher.Builder(context).build()
    publisher?.setStyle(
        BaseVideoRenderer.STYLE_VIDEO_SCALE,
        BaseVideoRenderer.STYLE_VIDEO_FILL
    )
    publisher?.setPublisherListener(this)
    /*
    publisher?.setAudioLevelListener(this)
    publisher?.setAudioStatsListener(this)
    publisher?.setMuteListener(this)
    publisher?.setRtcStatsReportListener(this)
    publisher?.setVideoListener(this)
    publisher?.setVideoStatsListener(this)
    */
    publisher?.setPublishAudio(publishAudio)
    publisher?.setPublishVideo(publishVideo)
    publisher?.setPublishCaptions(publishCaptions)
    publisher?.setAudioFallbackEnabled(audioFallbackEnabled)
    publisher?.setAudioFallbackEnabled(audioFallbackEnabled)

    sharedState.getPublishers().put(publisherId?: return, publisher?: return);
    if (publisher?.view != null) {
      publisher?.view?.layoutParams = LayoutParams(1000, 1000)
      this.addView(publisher?.view)
      requestLayout()
      val publisherView = publisher?.view
      if (publisherView != null) {
        publisherView.measure(
          View.MeasureSpec.makeMeasureSpec(publisherView.getMeasuredWidth(), View.MeasureSpec.EXACTLY),
          View.MeasureSpec.makeMeasureSpec(publisherView.getMeasuredHeight(), View.MeasureSpec.EXACTLY));
        publisherView.layout(publisherView.getLeft(), publisherView.getTop(), 640, 480)
        // publisherView.layout(publisherView.getLeft(), publisherView.getTop(), publisherView.getRight(), publisherView.getBottom())
      }
    }
  }


  override fun onStreamCreated(publisher: PublisherKit, stream: Stream) {
      val payload =
        Arguments.createMap().apply {
          putString("streamId", stream!!.streamId)
        }
      emitOpenTokEvent("onStreamCreated", payload)
  }

  override fun onStreamDestroyed(publisher: PublisherKit, stream: Stream) {
    /*
      val payload =
        Arguments.createMap().apply {
          putString("streamId", subscriber.getStream().streamId)
        }
      emitOpenTokEvent("onStreamDestroyed", payload)
    */
  }

  override fun onError(publisher: PublisherKit, opentokError: OpentokError) {
    val payload =
      Arguments.createMap().apply {
        putString("code", opentokError.errorCode.toString())
        putString("message", opentokError.message)
      }
    emitOpenTokEvent("onError", payload)
  }

  /*
  override fun onRtcStatsReport(publisher: PublisherKit, jsonArrayOfReports: String) {
      val statsArrayMap = Arguments.createArray().apply {
        for (stat: PublisherKit.PublisherRtcStats in stats) {
          val statMap = Arguments.createMap().apply {
            putString("connectionId", stat.connectionId);
            putString("jsonArrayOfReports", stat.jsonArrayOfReports);
          }
          pushMap(statMap);
        }
      }

      emitOpenTokEvent("onRtcStatsReport", statsArrayMap)
  }
  */

  override fun onAudioLevelUpdated(p0: PublisherKit?, p1: Float) {
    TODO("Not yet implemented")
  }

  override fun onRtcStatsReport(p0: PublisherKit?, p1: Array<out PublisherKit.PublisherRtcStats>?) {
    TODO("Not yet implemented")
  }

  override fun onAudioStats(p0: PublisherKit?, p1: Array<out PublisherKit.PublisherAudioStats>?) {
    TODO("Not yet implemented")
  }

  override fun onMuteForced(p0: PublisherKit?) {
    TODO("Not yet implemented")
  }

  override fun onVideoStats(p0: PublisherKit?, p1: Array<out PublisherKit.PublisherVideoStats>?) {
    TODO("Not yet implemented")
  }

  override fun onVideoDisabled(p0: PublisherKit?, p1: String?) {
    TODO("Not yet implemented")
  }

  override fun onVideoEnabled(p0: PublisherKit?, p1: String?) {
    TODO("Not yet implemented")
  }

  override fun onVideoDisableWarning(p0: PublisherKit?) {
    TODO("Not yet implemented")
  }

  override fun onVideoDisableWarningLifted(p0: PublisherKit?) {
    TODO("Not yet implemented")
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