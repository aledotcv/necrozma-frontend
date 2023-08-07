import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(NecrozmaNative());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge, overlays: [SystemUiOverlay.top]);
}

class NecrozmaNative extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PurpleGradientsScreen(),
    );
  }
}

class PurpleGradientsScreen extends StatefulWidget {
  @override
  _PurpleGradientsScreenState createState() => _PurpleGradientsScreenState();
}

class _PurpleGradientsScreenState extends State<PurpleGradientsScreen>
    with TickerProviderStateMixin {
  late AnimationController _typingAnimationController;
  late AnimationController _containerAnimationController;
  String typedText = '';
  int currentIndex = 0;
  String targetText = 'necrozma';
  bool obtainingVersion = true;
  String versionText = '';
  bool stopRequests = false;

  bool _isSTSelected = true;
  bool isFirstTime = true;
  bool serviceIntro = false;
  bool isSubmittable = false;
  String serviceName = '';
  TextEditingController _passkeyController = TextEditingController();
  TextEditingController _sessionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _containerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _startTypingAnimation(fetchVersion: true);
  }

  void _startTypingAnimation({bool fetchVersion = false}) async {
    for (int i = 0; i < targetText.length; i++) {
      await Future.delayed(Duration(milliseconds: 150));
      setState(() {
        typedText = targetText.substring(0, i + 1);
      });

      HapticFeedback.lightImpact();
    }

    await Future.delayed(Duration(seconds: 1));
    if (fetchVersion) {
      _getVersionFromServer();
    }
    else if(serviceIntro) {
      serviceIntro = false;
      HapticFeedback.heavyImpact();
      setState(() {
        versionText = serviceName;
      });
    }
  }

  void resetTypingAnimation() {
    setState(() {
      typedText = '';
    });
  }

  void startTypingNewText(String newText) {
    resetTypingAnimation();
    targetText = newText;
    _startTypingAnimation(fetchVersion: false);
  }
  Future<bool> checkNetworkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return true;
  }

  Future<void> _getVersionFromServer() async {
    setState(() {
      versionText = "Obtaining version...";
    });
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        versionText = 'No internet connection. Retrying in 5 seconds...';
        HapticFeedback.heavyImpact();
        Future.delayed(Duration(seconds: 5), () {
          _getVersionFromServer();
        });
      });
    } else {
      final response =
      await http.get(
          Uri.parse('https://resellers.necrozma.store/api/version.php'),
          headers: {
            'User-Agent': 'NecrozmaClient2.0',
            'Access-Control-Allow-Origin': '*',
          });
      if (response.statusCode == 200) {
        setState(() {
          obtainingVersion = false;
          versionText = response.body;
          HapticFeedback.mediumImpact();
          isSubmittable = true;
          _startContainerAnimation();
        });
      } else if (response.statusCode != 200)
      {
        setState(() {
          versionText = 'Service unavailable';
          HapticFeedback.heavyImpact();
        });
      }
      else{
        setState(() {
          versionText = 'Connection error';
          HapticFeedback.heavyImpact();
        });
      }
    }

  }

  void _startContainerAnimation() {
    _containerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _containerAnimationController.forward();
  }

  final String necrozmaUserAgent = 'NecrozmaClient2.0';
  int currentBalance = -1;
  int targetBalance = -1;
  String? necrozmaRequestId;
  String? statusCode;
  Timer? balanceUpdateTimer;
  int gatherCounter = 0;
  bool firstProximity = true;
  bool secondProximity = true;
  bool thirdProximity = true;

  Future<void> checkInventories(String session, String passkey) async {
    setState(() {
      versionText = 'Checking inventories...';
    });
    final url = 'https://api-live.necrozma.store/api/inventories';

    final headers = {
      'Necrozma-Session': session,
      'Necrozma-Passkey': passkey,
      'User-Agent': necrozmaUserAgent,
      'Access-Control-Allow-Origin': '*',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      necrozmaRequestId = response.headers['necrozma-request-id'];

      statusCode = response.statusCode.toString();
      if (response.statusCode == 200) {
        gatherAuricCells(session, passkey);
      }
      else if (response.statusCode == 401) {
        HandleError("passkey", true);
      }else if (response.statusCode == 403) {
        HandleError("session", true);
      } else if (response.statusCode == 400) {
        HandleError("passkey", true);
      } else if (response.statusCode == 404) {
        HandleError("passkeyNotFound", true);
      } else if (response.statusCode == 409) {
        HandleError("inventoryFound", true);
      } else {
        await Future.delayed(Duration(seconds: 5));
        HandleError("inventoryError", false);

      }
    } catch (e) {
      HandleError("inventoryError", false);

    }
  }

  Future<void> gatherAuricCells(String session, String passkey) async {
    setState(() {
      versionText = 'Requesting auric cells...';
    });
    final url = 'https://api-live.necrozma.store/api/gather';

    final headers = {
      'Necrozma-Session': session,
      'Necrozma-Passkey': passkey,
      'User-Agent': necrozmaUserAgent,
      'Access-Control-Allow-Origin': '*',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      necrozmaRequestId = response.headers['necrozma-request-id'];

      if (response.statusCode == 200) {
        setState(() {
          versionText = 'Requesting balance...';
        });
        startBalanceUpdates(session, passkey);
      }  else if (response.statusCode == 400) {
        HandleError("passkey", true);
      }
      else if (response.statusCode == 401) {
        HandleError("passkey", true);
      }
      else if (response.statusCode == 403) {
        HandleError("session", true);
      } else if (response.statusCode == 404) {
        HandleError("passkeyNotFound", true);
      } else if (response.statusCode == 409) {
        HandleError("alreadyCalled", false);
      } else {
        HandleError("failedGather", false);
      }
    } catch (e) {
      HandleError("failedGather", false);
    }
  }

  Future<void> getWalletBalance(String session, String passkey) async {
    final url = 'https://api-live.necrozma.store/api/wallet';

    final headers = {
      'Necrozma-Session': session,
      'Necrozma-Passkey': passkey,
      'User-Agent': necrozmaUserAgent,
      'Access-Control-Allow-Origin': '*',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      necrozmaRequestId = response.headers['necrozma-request-id'];

      if (response.statusCode == 200) {

        int balance = int.parse(response.body);

        if (currentBalance == -1 || currentBalance != balance) {
          currentBalance = balance;
          gatherCounter = 0;

          if (targetBalance == -1) {
            targetBalance = currentBalance + 1050;
          }

          setState(() {
            HapticFeedback.mediumImpact();
            versionText = ('Amount: $currentBalance Target: $targetBalance');
          });
        } else {

          gatherCounter++;
          if (gatherCounter == 2) {
            HandleError("failedGather", false);
            gatherCounter = 0;
          }
        }
        if (currentBalance >= 300 && firstProximity) {
          firstProximity = false;
          startTypingNewText("hang tight!");
        }
        if (currentBalance >= 800 && secondProximity) {
          secondProximity = false;
          startTypingNewText("almost there...");
        }
        if (currentBalance >= 1050 && thirdProximity) {
          thirdProximity = false;
          startTypingNewText("finishing things up...");
        }
      } else if (response.statusCode == 400) {
        HandleError("passkey", true);

      } else if (response.statusCode == 401) {
        HandleError("passkey", true);
      } else if (response.statusCode == 403) {
        HandleError("session", true);
      } else if (response.statusCode == 404) {
        HandleError("passkeyNotFound", true);
      } else if (response.statusCode == 409) {
        balanceUpdateTimer?.cancel();
        serviceIntro = true;
        serviceName = "stranger things";
        startTypingNewText("modded successfully");
        currentBalance = -1;
        targetBalance = -1;
        isSubmittable = true;
        firstProximity = true;
        secondProximity = true;
        thirdProximity = true;

        return;
      } else if (response.statusCode == 500) {
        HandleError("failedBalance", false);
      } else {
        HandleError("failedBalance", false);
      }
    } catch (e) {
      HandleError("failedBalance", false);
    }
  }

  Future<void> gainLegacyAndPrestige(String session, String passkey) async {
    final url = 'https://api-live.necrozma.store/api/legacyprestige';

    final headers = {
      'Necrozma-Session': session,
      'Necrozma-Passkey': passkey,
      'User-Agent': necrozmaUserAgent,
      'Access-Control-Allow-Origin': '*',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      necrozmaRequestId = response.headers['necrozma-request-id'];
      if (response.statusCode == 200) {
        await Future.delayed(Duration(seconds: 5));
        serviceIntro = true;
        serviceName = "legacy and prestige";
        startTypingNewText("modded successfully");
        isSubmittable = true;
      } else if (response.statusCode == 204) {
        HandleError("legacyFound", true);
      } else if (response.statusCode == 400) {
        HandleError("passkey", true);
      }
      else if (response.statusCode == 401) {
        HandleError("passkey", true);
      }
      else if (response.statusCode == 403) {
        HandleError("session", true);
      } else if (response.statusCode == 404) {
        HandleError("passkeyNotFound", true);
      } else {
        HandleError("legacyError", false);
      }
    } catch (e) {
      HandleError("legacyError", false);
    }
  }

  void HandleError(String message, bool shouldAllowRetry) {
    if(message == "passkey")
    {
      startTypingNewText("passkey is invalid");
    }
    else if(message == "session")
    {
      startTypingNewText("session is invalid");
    }
    else if(message == "illegalPasskey")
    {
      startTypingNewText("passkey unauthorized");
    }
    else if(message == "legacyError")
    {
      startTypingNewText("error while modding");
    }
    else if(message == "legacyFound")
    {
      startTypingNewText("account already modded");
    }
    else if(message == "failedBalance")
    {
      startTypingNewText("failed to retrieve balance");
    }
    else if(message == "failedGather")
    {
      startTypingNewText("failed to generate cells");
    }
    else if(message == "alreadyCalled")
    {
      startTypingNewText("service already requested");
    }
    else if(message == "inventoryError")
    {
      startTypingNewText("failed to retrieve inventory");
    }
    else if(message == "inventoryFound")
    {
      startTypingNewText("this account has stranger things");
    }
    else if(message == "passkeyNotFound")
    {
      startTypingNewText("passkey not found");
    }
    else {
      startTypingNewText("unknown error");
    }

    versionText = necrozmaRequestId ?? 'Could not retrieve request ID';
    if (shouldAllowRetry) {
      isSubmittable = true;
    } else {
      isSubmittable = false;
    }
  }

  void Mod_Logic(String passkey, String session, String service) async {
    serviceName = service;
    serviceIntro = true;
    isSubmittable = false;
    if (service == 'ST') {
      serviceName = "stranger things";
      startTypingNewText("now modding");
      await Future.delayed(Duration(seconds: 8));
      checkInventories(session, passkey);
    } else if (service == 'legacy') {
      startTypingNewText("now modding");
      await Future.delayed(Duration(seconds: 8));
      gainLegacyAndPrestige(session, passkey);
    }
  }

  void startBalanceUpdates(String session, String passkey) {

    balanceUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      getWalletBalance(session, passkey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _typingAnimationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8E2DE2),
                              Color(0xFF4A00E0),
                              Color(0xFF0000A0),
                            ],
                            stops: [
                              0.0,
                              0.5,
                              1.0,
                            ],
                            tileMode: TileMode.clamp,
                            transform:
                            GradientRotation(_typingAnimationController.value * 2 * 3.1416),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                typedText,
                                style: TextStyle(
                                    fontSize: 40.0,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              if (obtainingVersion) SizedBox(height: 20),
                              if (obtainingVersion)
                                Text(
                                  'Obtaining version...',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              if (!obtainingVersion && versionText.isNotEmpty) SizedBox(height: 10),
                              if (!obtainingVersion && versionText.isNotEmpty)
                                Text(
                                  versionText,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _containerAnimationController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: Visibility(
                            visible: !obtainingVersion,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            HapticFeedback.selectionClick();
                                            _isSTSelected = true;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _isSTSelected ? Colors.grey[300] : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'ST',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _isSTSelected ? Colors.black : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isSTSelected = false;
                                            HapticFeedback.selectionClick();

                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: !_isSTSelected ? Colors.grey[300] : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'Legacy',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: !_isSTSelected ? Colors.black : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: _passkeyController,
                                    decoration: InputDecoration(
                                      labelText: 'Passkey',
                                      labelStyle: TextStyle(color: Colors.white),
                                      hintStyle: TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.grey[200]),
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: _sessionController,
                                    decoration: InputDecoration(
                                      labelText: 'Session',
                                      labelStyle: TextStyle(color: Colors.white),
                                      hintStyle: TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.grey[200]),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      if(isSubmittable) {
                                        HapticFeedback.heavyImpact();
                                        String passkey = _passkeyController
                                            .text;
                                        String session = _sessionController
                                            .text;
                                        if (passkey.isEmpty ||
                                            session.isEmpty) {
                                          versionText =
                                          "Please enter passkey and session";
                                          setState(() {});
                                          return;
                                        }
                                        if (_isSTSelected) {
                                          Mod_Logic(passkey, session, "ST");
                                        }
                                        else {
                                          Mod_Logic(passkey, session, "legacy");
                                        }
                                      }
                                    },

                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.grey[300],
                                      onPrimary: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text('Submit'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _containerAnimationController.dispose();
    super.dispose();
  }
}