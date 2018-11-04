package com.opentokreactnative.utils;

import com.opentok.android.OpentokError;
import com.opentok.android.Publisher;
import com.opentok.android.PublisherKit;
import com.opentok.android.Subscriber;
import com.opentok.android.SubscriberKit;
import com.opentokreactnative.OTRN;

import java.util.ArrayList;
import java.util.Map;

public final class Utils {

    public static boolean didConnectionFail(OpentokError errorCode) {

        switch (errorCode.getErrorCode()) {
            case ConnectionFailed:
                return true;
            case ConnectionRefused:
                return true;
            case ConnectionTimedOut:
                return true;
            default:
                return false;
        }
    }

    public static boolean contains(ArrayList array, String value) {

        for (int i = 0; i < array.size(); i++) {
            if (array.get(i).equals(value)) {
                return true;
            }
        }
        return false;
    }

    public static String getPublisherId(PublisherKit publisherKit) {

        Map<String, Publisher> publishers = OTRN.sharedState.getPublishers();
        for (Map.Entry<String, Publisher> entry: publishers.entrySet()) {
            Publisher mPublisher = entry.getValue();
            if (mPublisher.equals(publisherKit)) {
                return entry.getKey();
            }
        }
        return "";
    }

    public static String getStreamIdBySubscriber(SubscriberKit subscriberKit) {

        Map<String, Subscriber> subscribers = OTRN.sharedState.getSubscribers();
        for (Map.Entry<String, Subscriber> entry: subscribers.entrySet()) {
            Subscriber mSubcriber = entry.getValue();
            if (mSubcriber.equals(subscriberKit)) {
                return entry.getKey();
            }
        }
        return "";
    }
}
