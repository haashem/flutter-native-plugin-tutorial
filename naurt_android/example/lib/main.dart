import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:naurt_android/naurt_android.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isInitialized = false;
  bool isRunning = false;
  bool isValidated = false;
  final naurt = NaurtAndroid.shared;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      isInitialized = await naurt.initialize(apiKey: 'api-key', precision: 5);

      naurt.onLocationChanged.listen((location) {
        print('onLocationChanged: ${location.toString()}');
      });

      naurt.onValidation = (bool isValid) {
        setState(() {
          isValidated = isValid;
        });
      };
      naurt.onRunning = (bool isRunning) {
        setState(() {
          this.isRunning = isRunning;
        });
      };
    } on PlatformException {
      isInitialized = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Naurt SDK'),
          actions: [
            TextButton(
                onPressed: () async {
                  if (await naurt.isRunning()) {
                    naurt.stop();
                  } else {
                    naurt.start();
                  }
                },
                child: const Text(
                  'Toggle Recording',
                  style: TextStyle(color: Colors.white),
                ))
          ],
        ),
        body: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusRow(
                    title: 'Is initialized?',
                    isValid: isInitialized,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  StatusRow(
                    title: 'Is validated?',
                    isValid: isValidated,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  StatusRow(
                    title: 'Is running?',
                    isValid: isRunning,
                  )
                ],
              ),
            )),
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  final String title;
  final bool isValid;
  const StatusRow({Key? key, required this.title, required this.isValid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
        ),
        isValid
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
              )
            : const Icon(
                Icons.cancel,
                color: Colors.red,
              )
      ],
    );
  }
}
