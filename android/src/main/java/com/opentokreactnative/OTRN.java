package com.opentokreactnative;

import com.opentok.android.Connection;
import com.opentok.android.Session;
import com.opentok.android.Stream;
import com.opentok.android.Subscriber;
import com.opentok.android.Publisher;

import java.util.concurrent.ConcurrentHashMap;

public class OTRN {
    public static OTRN sharedState;
    private ConcurrentHashMap<String, Stream> subscriberStreams = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Session> sessions = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Subscriber> subscribers = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Publisher> publishers = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, String> androidOnTopMap = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, String> androidZOrderMap = new ConcurrentHashMap<>();
    private ConcurrentHashMap<String, Connection> connections = new ConcurrentHashMap<>();

    public static synchronized OTRN getSharedState() {
        if (sharedState == null) {
            sharedState = new OTRN();
        }
        return sharedState;
    }

    public ConcurrentHashMap<String, String> getAndroidOnTopMap() {

        return this.androidOnTopMap;
    }

    public ConcurrentHashMap<String, String> getAndroidZOrderMap() {

        return this.androidZOrderMap;
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

    public ConcurrentHashMap<String, Publisher> getPublishers() {
        return this.publishers;
    }

    public ConcurrentHashMap<String, Connection> getConnections() {

        return this.connections;
    }

    private OTRN() {
    }
}