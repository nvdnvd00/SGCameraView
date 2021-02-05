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

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.views.image.ReactImageManager;
import com.facebook.react.views.image.ReactImageView;

public class SgCameraViewManager extends SimpleViewManager<ReactImageView> {

    public static final String REACT_CLASS = "SgCameraView";
    ReactApplicationContext mCallerContext;

    public SgCameraViewManager(ReactApplicationContext reactContext) {
        mCallerContext = reactContext;
    }

    public static String mBeat;
    public static ReadableMap mBeatDetail;
    public static ReadableMap mStyle;
    public static ReadableArray mLyrics;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public ReactImageView createViewInstance(ThemedReactContext context) {
//        AppCompatCheckBox cb = new AppCompatCheckBox(context);
//        cb.setChecked(true);
//        return cb;
        return new ReactImageView(context, Fresco.newDraweeControllerBuilder(), null, mCallerContext);
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
    }

    @ReactProp(name = "lyric")
    public void setLyric(ReactImageView view, @NonNull ReadableArray lyric) {
        mLyrics = lyric;
    }

}
