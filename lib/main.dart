import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MQTT Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MqttHomePage(),
    );
  }
}

class MqttHomePage extends StatefulWidget {
  const MqttHomePage({super.key});

  @override
  State<MqttHomePage> createState() => _MqttHomePageState();
}

class _MqttHomePageState extends State<MqttHomePage> {
  void _onClientDisconnected() {
    log('MQTT is disconnected');
  }

  void _onClientConnected() {
    log('MQTT is connected');

    _client.subscribe('eiot/dev/command', MqttQos.atLeastOnce);

    /**
     * Receive messages from the subscribed topic.
     */
    _client.updates!.listen((event) {
      final received = event[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(received.payload.message);

      log('Received message: $pt');

      try {
        final decoded = jsonDecode(pt);
        if (decoded['command'] == 'capture') {
          // do capture from camera
          log('Capturing....');
        }
      } on Exception catch (e) {
        log('Caught $e');
      }
    });
  }

  void _publish() {
    var payloadBuilder = MqttClientPayloadBuilder();
    payloadBuilder.addString('{"command":"capture"}');
    _client.publishMessage(
        'eiot/dev/command', MqttQos.atLeastOnce, payloadBuilder.payload!);
  }

  final _client = MqttServerClient('broker.emqx.io', '');

  @override
  void initState() {
    super.initState();

    _client.logging(on: true);
    _client.setProtocolV311();
    _client.keepAlivePeriod = 60;
    _client.connectTimeoutPeriod = 3000;
    _client.onDisconnected = _onClientDisconnected;
    _client.onConnected = _onClientConnected;

    _client.connect();
  }

  @override
  void dispose() {
    super.dispose();
    _client.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _publish,
              child: const Text('Send Capture Command'),
            ),
          ],
        ),
      ),
    );
  }
}
