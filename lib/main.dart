import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<dynamic> articles = [];
  Set<String> shownTitles = {};

  final String apiKey = 'YOUR_NEWSAPI_KEY'; // Replace with your NewsAPI key

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchNews();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  String detectSentiment(String headline) {
    final bullish = ["rises", "soars", "surges", "strengthens", "climbs"];
    final bearish = ["falls", "drops", "declines", "weakens", "plunges"];
    final lower = headline.toLowerCase();

    if (bullish.any((word) => lower.contains(word))) return "bullish";
    if (bearish.any((word) => lower.contains(word))) return "bearish";
    return "neutral";
  }

  Future<void> _fetchNews() async {
    final url =
        'https://newsapi.org/v2/everything?q=gold+usd&language=en&sortBy=publishedAt&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> newArticles = data['articles'] ?? [];

        // Filter out already shown news titles
        newArticles = newArticles
            .where((article) => !shownTitles.contains(article['title']))
            .toList();

        if (newArticles.isNotEmpty) {
          for (var article in newArticles) {
            shownTitles.add(article['title']);
            _showNotification(article['title']);
          }
          setState(() {
            articles.insertAll(0, newArticles);
          });
        }
      } else {
        print('Failed to fetch news: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }

  Future<void> _showNotification(String title) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gold_usd_news_channel',
      'Gold/USD News',
      channelDescription: 'Notifications for Gold/USD news',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Gold/USD News Update',
      title,
      platformChannelSpecifics,
      payload: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gold/USD News',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Gold/USD News & Sentiment'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchNews,
            )
          ],
        ),
        body: articles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  final sentiment = detectSentiment(article['title']);
                  Color borderColor = Colors.grey;
                  if (sentiment == "bullish") borderColor = Colors.green;
                  if (sentiment == "bearish") borderColor = Colors.red;

                  return Card(
                    shape: Border(left: BorderSide(color: borderColor, width: 5)),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: ListTile(
                      title: Text(article['title']),
                      subtitle: Text(article['source']['name'] ?? ''),
                      onTap: () {
                        // You can add URL launch here to open article['url']
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
