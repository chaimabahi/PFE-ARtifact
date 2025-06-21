import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import 'event_details_screen.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _openMap(double lat, double lng) async {
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open map')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening map: $e')),
        );
      }
    }
  }

  Widget _buildEventCard(Map<String, dynamic> event, String docId, BuildContext context) {
    if (event['eventDateTime'] is! Timestamp) return const SizedBox.shrink();
    final DateTime dateTime = (event['eventDateTime'] as Timestamp).toDate();
    final String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    final String formattedTime = DateFormat('HH:mm').format(dateTime);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final String title = event['title'] as String? ?? 'Untitled Event';
    final String location = event['location'] as String? ?? 'Unknown Location';
    final String imageUrl = event['imageURL'] as String? ?? '';
    final bool isFree = event['isFree'] as bool? ?? false;
    final bool isNew = event['isNew'] as bool? ?? false;
    final int participants = event['participants'] as int? ?? 0;
    final double locationLat = event['locationLat'] as double? ?? 0.0;
    final double locationLng = event['locationLng'] as double? ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (title == 'Untitled Event') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid event title')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsPage(
              eventId: docId,
              eventData: event,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDarkMode ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  child: const Icon(Icons.error, size: 50, color: Colors.red),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isNew) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(isDarkMode ? 0.4 : 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              color: isDarkMode ? Colors.red[200] : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isFree ? Colors.green : Colors.orange)
                              .withOpacity(isDarkMode ? 0.4 : 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFree ? 'Free' : 'Paid',
                          style: TextStyle(
                            color: isDarkMode
                                ? (isFree ? Colors.green[200] : Colors.orange[200])
                                : (isFree ? Colors.green : Colors.orange),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF003ADD),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$formattedDate - $formattedTime',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openMap(locationLat, locationLng),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDarkMode ? Colors.lightBlueAccent : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: isDarkMode ? Colors.black87 : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$participants+ Attending',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (title == 'Untitled Event') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid event title')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsPage(
                                eventId: docId,
                                eventData: event,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Details',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> _filterAndSortEvents(List<QueryDocumentSnapshot> events) async {
    final now = DateTime.now();
    List<QueryDocumentSnapshot> filteredEvents = [];

    for (var doc in events) {
      final event = doc.data() as Map<String, dynamic>;
      if (event['eventDateTime'] is! Timestamp) continue;
      final DateTime eventDateTime = (event['eventDateTime'] as Timestamp).toDate();
      final bool isNew = now.isBefore(eventDateTime);

      if (event['isNew'] is bool && event['isNew'] != isNew) {
        try {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(doc.id)
              .update({'isNew': isNew});
          event['isNew'] = isNew;
        } catch (e) {
          debugPrint('Error updating isNew for event ${doc.id}: $e');
        }
      }

      switch (_selectedFilter) {
        case 'All':
          filteredEvents.add(doc);
          break;
        case 'Old':
          if (eventDateTime.isBefore(now)) filteredEvents.add(doc);
          break;
        case 'Pending':
          if (eventDateTime.isAfter(now)) filteredEvents.add(doc);
          break;
        case 'Coming Soon':
          if (event['isNew'] == true) filteredEvents.add(doc);
          break;
      }
    }

    filteredEvents.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aIsNew = aData['isNew'] == true;
      final bIsNew = bData['isNew'] == true;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;
      return 0;
    });

    return filteredEvents;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Discover Events',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _filterAnimationController.forward(from: 0.0);
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        backgroundColor: isDarkMode ? Colors.black.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                        builder: (context) => _buildFilterMenu(isDarkMode),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        border: Border.all(
                          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 20,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedFilter,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error fetching events',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final events = snapshot.data!.docs;

                  return FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _filterAndSortEvents(events),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (futureSnapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Error processing events',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }
                      if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No events available',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }

                      final filteredEvents = futureSnapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final doc = filteredEvents[index];
                          return _buildEventCard(doc.data() as Map<String, dynamic>, doc.id, context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterMenu(bool isDarkMode) {
    final filters = [
      {'value': 'All', 'label': 'All Events', 'icon': Icons.event},
      {'value': 'Old', 'label': 'Past Events', 'icon': Icons.history},
      {'value': 'Pending', 'label': 'Upcoming Events', 'icon': Icons.schedule},
      {'value': 'Coming Soon', 'label': 'New Events', 'icon': Icons.new_releases},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...filters.map((filter) => FadeTransition(
            opacity: _filterAnimation,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter['value'] as String;
                });
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedFilter == filter['value']
                      ? (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFilter == filter['value']
                        ? (isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3))
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 20,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      filter['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}