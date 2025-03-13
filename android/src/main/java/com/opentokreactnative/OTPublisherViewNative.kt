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

class OTPublisherViewNative: FrameLayout, PublisherListener {
  private var session: Session? = null
  private var sessionId: String?= ""
  private var publisherId: String?= ""
  private var publishAudio = true
  private var publishVideo = true
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

  public fun setPublishVideo(value: Boolean) {
    publishVideo = value
    publisher?.setPublishVideo(value)
  }

  fun publishStream(session: Session) {
    publisher = Publisher.Builder(context).build()
    publisher?.setStyle(
        BaseVideoRenderer.STYLE_VIDEO_SCALE,
        BaseVideoRenderer.STYLE_VIDEO_FILL
    )
    publisher?.setPublisherListener(this)
    // publisher?.setRtcStatsReportListener(this)
    publisher?.setPublishAudio(true)
    publisher?.setPublishVideo(true)

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