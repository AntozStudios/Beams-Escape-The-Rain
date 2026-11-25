package com.antoz.beams;

import android.app.Activity;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.rewardedinterstitial.*;
import com.google.android.ump.*;
import java.util.concurrent.atomic.AtomicInteger;

public final class BeamsMobile {
    private static volatile RewardedInterstitialAd rewarded;
    private static final AtomicInteger earned = new AtomicInteger();
    private static AdView banner;
    private static boolean loading, initialized, wantsBanner;
    private static Activity owner;
    private static String rewardUnit, bannerUnit;

    public static String takeLogin() { return LoginCallback.result.getAndSet(""); }
    public static int takeReward() { return earned.getAndSet(0); }
    public static boolean ready() { return rewarded != null; }

    public static void initialize(Activity activity, boolean debug) {
        activity.runOnUiThread(() -> {
            if (owner == activity) return;
            owner = activity;
            rewardUnit = debug ? "ca-app-pub-3940256099942544/5354046379" : "ca-app-pub-1320039869895590/5136125260";
            bannerUnit = debug ? "ca-app-pub-3940256099942544/6300978111" : "ca-app-pub-1320039869895590/6775514145";
            ConsentInformation consent = UserMessagingPlatform.getConsentInformation(activity);
            consent.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, error -> {
                    if (error == null && consent.canRequestAds()) {
                        MobileAds.initialize(activity, status -> activity.runOnUiThread(() -> {
                            initialized = true;
                            load(activity);
                            if (wantsBanner) setBanner(activity, true);
                        }));
                    }
                }), error -> {});
        });
    }

    private static void load(Activity activity) {
        if (loading || rewarded != null || !initialized) return;
        loading = true;
        RewardedInterstitialAd.load(activity, rewardUnit, new AdRequest.Builder().build(),
            new RewardedInterstitialAdLoadCallback() {
                @Override public void onAdLoaded(RewardedInterstitialAd ad) {
                    loading = false;
                    rewarded = ad;
                }
                @Override public void onAdFailedToLoad(LoadAdError error) {
                    loading = false;
                    new android.os.Handler(activity.getMainLooper()).postDelayed(() -> {
                        if (owner == activity && !activity.isDestroyed()) load(activity);
                    }, 30000);
                }
            });
    }

    public static void watch(Activity activity) {
        activity.runOnUiThread(() -> {
            RewardedInterstitialAd ad = rewarded;
            if (ad == null) { load(activity); return; }
            rewarded = null;
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() { load(activity); }
                @Override public void onAdFailedToShowFullScreenContent(AdError error) { load(activity); }
            });
            ad.show(activity, reward -> earned.addAndGet(reward.getAmount()));
        });
    }

    public static void setBanner(Activity activity, boolean visible) {
        activity.runOnUiThread(() -> {
            wantsBanner = visible;
            if (banner != null) {
                ((ViewGroup)banner.getParent()).removeView(banner);
                banner.destroy();
                banner = null;
            }
            if (!visible || !initialized) return;
            banner = new AdView(activity);
            banner.setAdSize(AdSize.BANNER);
            banner.setAdUnitId(bannerUnit);
            activity.addContentView(banner, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL));
            banner.loadAd(new AdRequest.Builder().build());
        });
    }
}
