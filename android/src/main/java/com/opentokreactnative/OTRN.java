package com.opentokreactnative;

import android.widget.FrameLayout;

import com.opentok.android.Publisher;
import com.opentok.android.Session;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;

import java.util.concurrent.ConcurrentHashMap;

/**
 * Created by manik on 1/10/18.
 */

public class OTRN {

    public static OTRN sharedState;
    private Session mSession;
    private Publisher mPublisher;

    private ConcurrentHashMap<String, Stream> subscriberStreams = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Subscriber> subscribers = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, FrameLayout> subscriberViewContainers = new ConcurrentHashMap<>();
    private FrameLayout publisherViewContainer;

    public static synchronized OTRN getSharedState() {

        if (sharedState == null) {
            sharedState = new OTRN();
        }
        return sharedState;
    }

    public synchronized Session getSession() {

        return this.mSession;
    }

    public synchronized Publisher getPublisher() {

        return this.mPublisher;
    }

    public ConcurrentHashMap<String, Stream> getSubscriberStreams() {

        return this.subscriberStreams;
    }

    public ConcurrentHashMap<String, Subscriber> getSubscribers() {

        return this.subscribers;
    }

    public ConcurrentHashMap<String, FrameLayout> getSubscriberViewContainers() {

        return this.subscriberViewContainers;
    }

    public synchronized FrameLayout getPublisherViewContainer() {

        return this.publisherViewContainer;
    }
    public synchronized void setSession(Session mSession) {

        this.mSession = mSession;
    }
    public synchronized void setPublisher(Publisher mPublisher) {

        this.mPublisher = mPublisher;
    }

    public synchronized void setPublisherViewContainer(FrameLayout mPublisherViewContainer) {

        this.publisherViewContainer = mPublisherViewContainer;
    }

    private OTRN() {}
}
