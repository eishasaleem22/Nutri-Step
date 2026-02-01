package com.example.flutter_projects

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class MyNativeAdFactory(val inflater: LayoutInflater) : NativeAdFactory {
    override fun createNativeAd(ad: NativeAd, opts: Map<String,Any>?): NativeAdView {
        val adView = inflater.inflate(R.layout.native_ad_layout, null) as NativeAdView
        // after inflate and binding the rest…

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        (adView.headlineView as TextView).text = ad.headline
        adView.bodyView = adView.findViewById(R.id.ad_body)
        (adView.bodyView as TextView).text = ad.body
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        ad.icon?.let{ (adView.iconView as ImageView).setImageDrawable(it.drawable) }
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        (adView.callToActionView as Button).text = ad.callToAction

        // AdChoices & close
        adView.setAdChoicesView(adView.findViewById(R.id.ad_choices_view))
        adView.findViewById<ImageView>(R.id.ad_close)
            .setOnClickListener { adView.visibility = View.GONE }

        adView.setNativeAd(ad)
        return adView
    }
}
