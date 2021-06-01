import 'dart:convert';
import 'dart:ffi';

import 'package:intl/intl.dart' as intl;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:another_brother/custom_paper.dart';
import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';
import 'package:flutter/services.dart';

import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sup? Pushups!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Sup? Pushups!'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  double _percent = 0.0;
  var _start;

  int _previousCounter = 0;
  int _nextGoal = 0;

  Color _backgroundColor = Colors.white;

  _MyHomePageState() {
    _loadPrevious();
  }

  void _loadPrevious() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _previousCounter = prefs.getInt('counter') ?? 0;
    _nextGoal = prefs.getInt('nextGoal') ?? 0;
  }

  void _resetPrevious() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('counter', 0);
    prefs.setInt('nextGoal', 0);
  }

  void _incrementCounter() {
    setState(() {
      _backgroundColor = Colors.blue;

      if (_counter == 0) {
        _start = DateTime.now();
      }
      _counter++;
      _percent = _counter / 10.0;
      if (_percent > 1.0) {
        _percent = 1.0;
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _backgroundColor = Colors.white;
      });
    });
  }

  void _resetProgress() {
    setState(() {
      _counter = 0;
      _percent = 0.0;
      _start = null;
      _previousCounter = 0;
      _nextGoal = 0;
    });
    _resetPrevious();
  }

  void _done() async {
    //print(_start);
    //print(DateTime.now());
    Duration difference = DateTime.now().difference(_start);
    //print(difference.inMinutes);
    //print(difference.inSeconds.remainder(60));
    int count = _counter;
    int nextGoal = calculateNextGoal(_counter, difference);

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DonePage(count, difference, nextGoal)));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('counter', _counter);
    prefs.setInt('nextGoal', nextGoal);

    setState(() {
      _previousCounter = _counter;
      _nextGoal = nextGoal;
      _counter = 0;
      _percent = 0.0;
      _start = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(children: <Widget>[
        Image.asset('assets/images/silhouette_640.png'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Text(
            "Previous total: $_previousCounter",
            style: Theme.of(context).textTheme.headline6,
          ),
          Text(
            "Next goal: $_nextGoal",
            style: Theme.of(context).textTheme.headline6,
          )
        ]),
        Expanded(
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _incrementCounter,
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  //color: Colors.blue,
                  children: //FittedBox()
                      <Widget>[
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    LinearPercentIndicator(
                        percent: _percent,
                        width: MediaQuery.of(context).size.width)
                  ])),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          ElevatedButton(onPressed: _resetProgress, child: Text("Reset")),
          ElevatedButton(onPressed: _done, child: Text("I'm done"))
        ])
      ]),
    );
  }
}

class DonePage extends StatefulWidget {
  final int _count;
  final Duration _difference;
  final int _nextGoal;

  DonePage(this._count, this._difference, this._nextGoal);

  @override
  _DonePageState createState() => _DonePageState();
}

class _DonePageState extends State<DonePage> {
  ConfettiController _controllerCenter;
  ui.Image _logo;

  @override
  void initState() {
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 3));
    _controllerCenter.play();
    _loadLogo();
    super.initState();
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  _loadLogo() async {
    ByteData bd = await rootBundle.load("assets/images/silhouette_640.png");
    final Uint8List bytes = Uint8List.view(bd.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image logo = (await codec.getNextFrame()).image;

    setState(() => _logo = logo);
  }

  void print(BuildContext context) async {
    var printer = new Printer();
    var printInfo = PrinterInfo();
    printInfo.printerModel = Model.QL_1110NWB;
    printInfo.printMode = PrintMode.FIT_TO_PAGE;
    printInfo.isAutoCut = true;
    printInfo.port = Port.BLUETOOTH;
    // Set the label type.
    printInfo.labelNameIndex = QL1100.ordinalFromID(QL1100.W103.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);

    // Get a list of printers with my model available in the network.
    List<BluetoothPrinter> printers =
        await printer.getBluetoothPrinters([Model.QL_1110NWB.getName()]);

    if (printers.isEmpty) {
      // Show a message if no printers are found.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("No paired printers found on your device."),
        ),
      ));

      return;
    }
    // Get the IP Address from the first printer found.
    printInfo.macAddress = printers.single.macAddress;

    printer.setPrinterInfo(printInfo);
    //printer.printImage(await loadImage('assets/brother_hack.png'));
    printer.printImage(await makeImage());
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData img = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(img.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image> makeImage() async {
    ui.PictureRecorder recorder = new ui.PictureRecorder();
    Canvas c = new Canvas(recorder);

    var paint = Paint();
    paint.color = Colors.white;
    c.drawPaint(paint);

    //c.drawImage(_logo, new Offset(0.0, 0.0), new Paint());
    paintImage(canvas: c, image: _logo, rect: Rect.fromLTRB(0, 0, 300, 100));

    TextPainter dateTP = TextPainter(
        text: TextSpan(
            style: new TextStyle(color: Colors.black, fontSize: 20.0),
            text: intl.DateFormat('yyy-MM-dd - kk:mm').format(DateTime.now())),
        textDirection: TextDirection.ltr);
    dateTP.layout();
    dateTP.paint(c, const Offset(300.0, 0.0));

    TextPainter countTP = TextPainter(
        text: TextSpan(
            style: new TextStyle(color: Colors.black, fontSize: 20.0),
            text: "Pushups: ${widget._count}"),
        textDirection: TextDirection.ltr);
    countTP.layout();
    countTP.paint(c, const Offset(300.0, 30.0));

    TextPainter differenceTP = TextPainter(
        text: TextSpan(
            style: new TextStyle(color: Colors.black, fontSize: 20.0),
            text: "Time: ${formatDuration()}"),
        textDirection: TextDirection.ltr);
    differenceTP.layout();
    differenceTP.paint(c, const Offset(300.0, 60.0));

    TextPainter nextGoalTP = TextPainter(
        text: TextSpan(
            style: new TextStyle(color: Colors.black, fontSize: 50.0),
            text: "Next goal: ${widget._nextGoal}"),
        textDirection: TextDirection.ltr);
    nextGoalTP.layout();
    nextGoalTP.paint(c, const Offset(170.0, 100.0));

    ui.Picture p = recorder.endRecording();

    ui.Image i = await p.toImage(600, 170);
    ByteData pngBytes = await i.toByteData(format: ui.ImageByteFormat.png);

    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(pngBytes.buffer),
        (ui.Image pngBytes) {
      return completer.complete(pngBytes);
    });
    return completer.future;
  }

  Future<ByteData> imageByteData() async {
    var i = await makeImage();
    return await i.toByteData(format: ui.ImageByteFormat.png);
  }

  String formatDuration() {
    String val = "";
    if (widget._difference.inMinutes > 0) {
      val += "${widget._difference.inMinutes} minutes";
    }
    if (widget._difference.inSeconds.remainder(60) > 0) {
      if (val != "") {
        val += " and ${widget._difference.inSeconds.remainder(60)} seconds";
      } else {
        val += "${widget._difference.inSeconds.remainder(60)} seconds";
      }
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ConfettiWidget(
        confettiController: _controllerCenter,
        blastDirectionality: BlastDirectionality.explosive,
        particleDrag: 0.05,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.05,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple
        ], // manually specify the colors to be used
      ),
      Center(child: Text("Congratulations!", style:  new TextStyle(color: Colors.black, fontSize: 50.0))),
      SizedBox(height: 20.0),
      Text("You did ${widget._count} pushups in ${formatDuration()}.",  style: new TextStyle(color: Colors.black, fontSize: 25.0)),
                  SizedBox(height: 20.0),
      Text("Your next goal is ${widget._nextGoal} pushups.", style:  new TextStyle(color: Colors.black, fontSize: 25.0)),
                  SizedBox(height: 50.0),
      /*Container(
        width: 600,
        height: 200,
        child: FutureBuilder<ByteData>(
            //future: makeImage(),
            future: imageByteData(),
            builder: (BuildContext context, AsyncSnapshot<ByteData> snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data.buffer.asUint8List());
              } else {
                return Text("waiting");
              }
            }),
      ),*/
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        ElevatedButton(onPressed: () => print(context), child: Text("Print")),
        ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Okay")),
      ]),
    ])));
  }
}

class ImageDialog extends StatelessWidget {
  ImageDialog(this.image);

  final dynamic image;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: MemoryImage(image), fit: BoxFit.contain)),
      ),
    );
  }
}

int calculateNextGoal(int currentCount, Duration length) {
  // The expectation is that 1 pushup per second is average. Performing faster or slower than that adjusts the new goal to an according multiplier.
  return (currentCount / length.inSeconds * currentCount).round() +
      currentCount;
}
