import 'package:flutter/material.dart';

import '../../../shared/l10n/app_localizations.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('notifications')),
      ),
      body: Center(
        child: Text(
          localizations.translate('no notifications yet'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}