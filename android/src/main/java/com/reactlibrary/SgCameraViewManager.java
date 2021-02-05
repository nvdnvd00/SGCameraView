package com.reactlibrary;

import android.graphics.Color;
import android.support.annotation.NonNull;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;

import java.lang.String;


import androidx.appcompat.widget.AppCompatCheckBox;

import com.facebook.drawee.backends.pipeline.Fresco;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.views.image.ReactImageManager;
import com.facebook.react.views.image.ReactImageView;

public class SgCameraViewManager extends SimpleViewManager<ReactImageView> {

    public static final String REACT_CLASS = "SgCameraView";
    ReactApplicationContext mCallerContext;

    public SgCameraViewManager(ReactApplicationContext reactContext) {
        mCallerContext = reactContext;
    }

    private RCTEventEmitter mEventEmitter;

    public static String mBeat;
    public static ReadableMap mBeatDetail;
    public static ReadableMap mStyle;
    public static ReadableArray mLyrics;

    public enum Events {
        EVENT_RECORDING_END("onRecordingEnd");
        private final String mName;

        Events(final String name) {
            mName = name;
        }

        @Override
        public String toString() {
            return mName;
        }
    }


    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public ReactImageView createViewInstance(ThemedReactContext context) {
        ReactImageView view = new ReactImageView(context, Fresco.newDraweeControllerBuilder(), null, mCallerContext);
        mEventEmitter = context.getJSModule(RCTEventEmitter.class);
//        onRecordingEnd(view, "");
        return view;
    }


    public void onRecordingEnd(ReactImageView v, String mergedUrl) {
        WritableMap event = Arguments.createMap();
        event.putString("mergedUrl", mergedUrl);
        mEventEmitter.receiveEvent(v.getId(), Events.EVENT_RECORDING_END.toString(), event);
    }


    @ReactProp(name = "beatDetail")
    public void setBeatDetail(ReactImageView view, @NonNull ReadableMap beatDetail) {
        mBeatDetail = beatDetail;

    }

    @ReactProp(name = "beat")
    public void setBeat(ReactImageView view, @NonNull String beat) {
        mBeat = beat;
    }

    @ReactProp(name = "style")
    public void setStyle(ReactImageView view, @NonNull ReadableMap style) {
        mStyle = style;
        int width = style.hasKey("width") ? style.getInt("width") : 0;
        int height = style.hasKey("height") ? style.getInt("height") : 0;
        Log.d("style width", String.valueOf(width));
        Log.d("style height", String.valueOf(height));
        Log.d("style", String.valueOf(style));

    }

    @ReactProp(name = "lyric")
    public void setLyric(ReactImageView view, @NonNull ReadableArray lyric) {
        mLyrics = lyric;
    }

}
