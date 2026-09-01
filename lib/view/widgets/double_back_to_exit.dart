import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Wrap your bottom-nav host screen's root Scaffold with this. Pressing
/// back once shows a toast; pressing back again within [resetAfter] exits
/// the app entirely (instead of navigating anywhere, e.g. back to a splash
/// screen).
class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final Duration resetAfter;

  const DoubleBackToExit({
    super.key,
    required this.child,
    this.resetAfter = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();
        final isSecondPress =
            _lastBackPress != null &&
            now.difference(_lastBackPress!) < widget.resetAfter;

        if (isSecondPress) {
          // Actually exit the app — SystemNavigator.pop() closes it cleanly
          // on Android rather than popping to whatever route sits beneath
          // this one (e.g. a splash screen).
          SystemNavigator.pop();
          return;
        }

        _lastBackPress = now;
        Fluttertoast.showToast(
          msg: 'Press back again to exit',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      },
      child: widget.child,
    );
  }
}
