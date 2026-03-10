import 'dart:io';
import 'package:hisotech/business/utils/webview/webview_controller.dart';
import 'package:hisotech/business/utils/notifications/notification_handler.dart';
import 'package:hisotech/view/components/page_buttons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hisotech/main.dart';

class WebViewAppPage extends StatefulWidget {
  const WebViewAppPage({
    Key? key,
    required String webviewURL,
    this.title = '',
  })  : webviewURL = webviewURL,
        super(key: key);

  final String webviewURL;
  final String title;

  @override
  _WebViewAppPageState createState() => _WebViewAppPageState();
}

class _WebViewAppPageState extends State<WebViewAppPage> {
  static const Color themeColor = Color(0xFF16A34A);
  late WebViewController webviewController;
  late bool isPageLoading;
  late bool errorOccured;
  late NotificationHandler notificationHandler;

  @override
  void initState() {
    super.initState();
    _registerNotificationHandler();
    webviewController = _bindWebViewControllerToState();
    webviewController.setBackgroundColor(Colors.white);
    isPageLoading = true;
    errorOccured = false;
  }

  Future<void> _handleBackPress() async {
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: themeColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: _handleBackPress,
          ),
          title: Text(
            widget.title.isEmpty ? "ANGEL LINH CHI" : widget.title,
            style: GoogleFonts.beVietnamPro(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => webviewController.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            const ColoredBox(color: Colors.white, child: SizedBox.expand()),
            WebViewWidget(controller: webviewController),
            if (isPageLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(color: themeColor),
                ),
              ),
            if (errorOccured)
              PageButtons(
                buttonColor: themeColor,
                webViewController: webviewController,
              ),
          ],
        ),
      ),
    );
  }

  void _registerNotificationHandler() {
    notificationHandler = NotificationHandler(appID: 'ONESIGNAL_APP_ID');
    if (!Platform.isAndroid) {
      notificationHandler.getPermission().then(
            (bool wasPermissionGiven) {
          if (wasPermissionGiven) return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permission not given!'),
              ),
            );
          }
        },
      );
    }
    notificationHandler.establishCallbacks(context);
  }

  WebViewController _bindWebViewControllerToState() {
    return createWebViewController(
      webviewURL: widget.webviewURL,
      onPageStarted: (String url) {
        if (!mounted) return;
        setState(() {
          isPageLoading = true;
          errorOccured = false;
        });
      },
      onPageFinished: (String url) {
        if (!mounted) return;
        setState(() {
          isPageLoading = false;
          errorOccured = false;
        });
      },
      onWebResourceError: (WebResourceError error) {
        if (!mounted) return;
        setState(() {
          isPageLoading = false;
          errorOccured = true;
        });
      },
    );
  }
}