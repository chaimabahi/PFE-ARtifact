import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/theme_provider.dart';
import '../navigation/screens/main_navigation.dart';

class EventDetailsPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailsPage({super.key, required this.eventId, required this.eventData});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> with SingleTickerProviderStateMixin {
  bool isParticipating = false;
  bool isLoadingParticipation = true;
  late final String userId;
  late AnimationController _animationController;
  late Animation<double> _fingerAnimation;

  @override
  void initState() {
    super.initState();
    print('Event Data: ${widget.eventData}');
    userId = FirebaseAuth.instance.currentUser!.uid;
    checkParticipation();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fingerAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> checkParticipation() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Failed to fetch user data: Request timed out');
      });

      final List<dynamic> participantIds = userDoc.exists && userDoc.data()!.containsKey('participantIds')
          ? (userDoc['participantIds'] ?? [])
          : [];
      final eventParticipation = participantIds.any((event) => event['eventId'] == widget.eventId);
      setState(() {
        isParticipating = eventParticipation;
        isLoadingParticipation = false;
      });
    } catch (e) {
      print('Error checking participation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load participation status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isParticipating = false;
        isLoadingParticipation = false;
      });
    }
  }

  Future<void> toggleParticipation() async {
    if (isParticipating) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final isDarkMode = themeProvider.isDarkMode;

          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              'Leave Event',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Text(
              'Are you sure you want to leave this event?',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    setState(() {
      isLoadingParticipation = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final batch = FirebaseFirestore.instance.batch();

      if (isParticipating) {
        batch.update(userRef, {
          'participantIds': FieldValue.arrayRemove([
            {'eventId': widget.eventId, 'title': widget.eventData['title']}
          ]),
        });
      } else {
        batch.update(userRef, {
          'participantIds': FieldValue.arrayUnion([
            {'eventId': widget.eventId, 'title': widget.eventData['title']}
          ]),
        });
      }

      await batch.commit();

      setState(() {
        isParticipating = !isParticipating;
        isLoadingParticipation = false;
      });
    } catch (e) {
      print('Error toggling participation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update participation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isLoadingParticipation = false;
      });
    }
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  bool get _canParticipate {
    final eventDateTime = (widget.eventData['eventDateTime'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    return eventDateTime != null && now.isBefore(eventDateTime);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [Colors.grey[900]!, Colors.grey[800]!]
                        : [Colors.white, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xff003add),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: event['imageURL'] as String? ?? '',
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "About:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['about'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "This course includes:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['includes'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 18,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Current: ${event['participants'] as int? ?? 0} Participants",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: isDarkMode ? Colors.greenAccent : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event['eventDateTime'] != null
                                ? DateFormat('dd MMM yyyy – HH:mm')
                                .format((event['eventDateTime'] as Timestamp).toDate())
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: isDarkMode ? Colors.lightBlueAccent : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event['location'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 18,
                            color: isDarkMode ? Colors.tealAccent : Colors.teal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (event['isFree'] as bool? ?? false) ? "Free" : "Paid",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.white
                                  : (event['isFree'] as bool? ?? false) ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: InkWell(
                          onTap: () {
                            final lat = event['locationLat'] as double? ?? 0.0;
                            final lng = event['locationLng'] as double? ?? 0.0;
                            _openMap(lat, lng);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/map.jpg',
                                  height: 120,
                                  width: 240,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                child: ScaleTransition(
                                  scale: _fingerAnimation,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withOpacity(0.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.touch_app,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_canParticipate)
                        Center(
                          child: isLoadingParticipation
                              ? const CircularProgressIndicator()
                              : GestureDetector(
                            onTap: toggleParticipation,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              child: Text(
                                isParticipating ? "Leave Event" : "Participate",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}