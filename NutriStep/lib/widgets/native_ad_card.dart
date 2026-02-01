import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';



class NativeAdCard extends StatefulWidget {
  @override
  _NativeAdCardState createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  late NativeAd _ad;
  bool _loaded = false;

  @override
  void initState() {
    // in your NativeAdCard initState
    _ad = NativeAd(
      adUnitId: 'ca-app-pub-3940256099942544/2247696110',  // ← TEST ID
      factoryId: 'native_ad_view',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('✅ Native ad loaded');
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Native ad failed: $error');
          ad.dispose();
        },
      ),
    )..load();

  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loaded
        ? Container(
      margin: EdgeInsets.all(16),
      height: 100, // match your XML’s wrap_content + padding
      child: AdWidget(ad: _ad),
    )
        : SizedBox.shrink();
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class NativeAdCard extends StatefulWidget {
//   const NativeAdCard({Key? key}) : super(key: key);
//   @override _NativeAdCardState createState() => _NativeAdCardState();
// }
//
// class _NativeAdCardState extends State<NativeAdCard> {
//   NativeAd? _ad;
//   bool _loaded = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _ad = NativeAd(
//       adUnitId: 'ca-app-pub-6515345556540464/6424207422',     // your live Native ID
//       factoryId: 'native_ad_view',
//       request: const AdRequest(),
//       listener: NativeAdListener(
//         onAdLoaded: (_) => setState(() => _loaded = true),
//         onAdFailedToLoad: (ad, e) {
//           ad.dispose();
//           debugPrint('NativeAd Error: $e');
//         },
//       ),
//     )..load();
//   }
//
//   @override
//   void dispose() {
//     _ad?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext c) {
//     if (!_loaded) return const SizedBox.shrink();
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [BoxShadow(blurRadius:4, color:Colors.black26)],
//         ),
//         padding: const EdgeInsets.all(12),
//         child: SizedBox(
//           height: 100,
//           child: AdWidget(ad: _ad!),
//         ),
//       ),
//     );
//   }
// }
//
//
