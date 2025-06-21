import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Added for min function

class FadeSlideAnimation extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const FadeSlideAnimation({
    Key? key,
    required this.controller,
    required this.delay,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay,
        min(delay + 0.4, 1.0), // Ensure end <= 1.0
        curve: Curves.easeInOut,
      ),
    );

    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay,
          min(delay + 0.4, 1.0), // Ensure end <= 1.0
          curve: Curves.easeInOut,
        ),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

class ScaleAnimation extends StatelessWidget {
  final AnimationController controller;
  final Widget child;

  const ScaleAnimation({
    Key? key,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: child,
    );
  }
}

class CarouselAnimation extends StatelessWidget {
  final AnimationController controller;
  final List<Widget> items;
  final double height;
  final Function(int, CarouselPageChangedReason)? onPageChanged;

  const CarouselAnimation({
    Key? key,
    required this.controller,
    required this.items,
    required this.height,
    this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.2, 0.6, curve: Curves.easeInOut),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: CarouselSlider(
        options: CarouselOptions(
          height: height,
          viewportFraction: 1.0,
          enableInfiniteScroll: false,
          scrollDirection: Axis.horizontal,
          initialPage: 0,
          enlargeCenterPage: false,
          onPageChanged: onPageChanged,
        ),
        items: items.map((item) {
          return Builder(
            builder: (BuildContext context) {
              return item;
            },
          );
        }).toList(),
      ),
    );
  }
}