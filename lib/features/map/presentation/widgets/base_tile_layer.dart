import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/constants.dart';

class BaseTileLayer extends StatelessWidget {
  const BaseTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: AppConstants.mapURL,
      userAgentPackageName: AppConstants.userAgentPackageName,
    );
  }
}
