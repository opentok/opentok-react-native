package com.opentokreactnative;

import com.opentok.android.Session;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;
import java.util.concurrent.ConcurrentHashMap;

public class OTRN {

    public static OTRN sharedState;

    private ConcurrentHashMap<String, Stream> subscriberStreams = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Session> sessions = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Subscriber> subscribers = new ConcurrentHashMap<>();

    public static synchronized OTRN getSharedState() {

        if (sharedState == null) {
            sharedState = new OTRN();
        }
        return sharedState;
    }

    public ConcurrentHashMap<String, Stream> getSubscriberStreams() {

        return this.subscriberStreams;
    }


    public ConcurrentHashMap<String, Session> getSessions() {

        return this.sessions;
    }

    public ConcurrentHashMap<String, Subscriber> getSubscribers() {
        return this.subscribers;
    }

    private OTRN() {}
}
