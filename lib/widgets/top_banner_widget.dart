import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:portfolio_chinoshop/images/no_img_base64.dart';


class TopBannerCarousel extends StatelessWidget {
  const TopBannerCarousel({Key? key}) : super(key: key);

  Future<List<Widget>> _fetchBanners() async {
    final snapshot = await FirebaseFirestore.instance.collection('topBanner').get();
    return snapshot.docs.map((doc) {
      final imgBase64 = doc['imgBase64'] as String?;
      Widget imageWidget;

      if (imgBase64 != null && imgBase64.isNotEmpty) {
        final imageBytes = base64Decode(imgBase64);
        imageWidget = Image.memory(
          imageBytes,
          width: 330,
          height: 220,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = Image.asset(
          noImgBase64,
          width: 330,
          height: 220,
          fit: BoxFit.cover,
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: imageWidget,
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _fetchBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('バナーがありません'));
        }

        return CarouselSlider(
          options: CarouselOptions(
            height: 220,
            viewportFraction: 1.0,
            autoPlay: true,
            enlargeCenterPage: true,
          ),
          items: snapshot.data!,
        );
      },
    );
  }
}
