import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:memorylens/components/offline_banner.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_bloc.dart';
import 'package:memorylens/features/connectivity/ui/bloc/connectivity_state.dart';

/// Wraps the whole app: puts the «Sin conexión» banner above every screen
/// while the device is offline. Needs a ConnectivityBloc above it.
class ConnectivityShell extends StatelessWidget {
  final Widget child;

  const ConnectivityShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        return Column(
          children: [
            if (!state.online) const OfflineBanner(),
            Expanded(
              // The banner already covers the status bar, so the screens
              // below must not pad for it a second time.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: !state.online,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
