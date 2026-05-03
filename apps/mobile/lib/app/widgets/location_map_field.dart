import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LocationSelection {
  const LocationSelection({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  final double? latitude;
  final double? longitude;
  final double radiusKm;

  bool get hasPoint => latitude != null && longitude != null;
}

class LocationMapField extends StatefulWidget {
  const LocationMapField({
    required this.label,
    required this.helper,
    required this.radiusLabel,
    required this.onChanged,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusKm = 60,
    this.defaultCenter = const LatLng(27.7172, 85.3240),
    this.defaultZoom = 11,
    super.key,
  });

  final String label;
  final String helper;
  final String radiusLabel;
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadiusKm;
  final LatLng defaultCenter;
  final double defaultZoom;
  final ValueChanged<LocationSelection> onChanged;

  @override
  State<LocationMapField> createState() => _LocationMapFieldState();
}

class _LocationMapFieldState extends State<LocationMapField> {
  final MapController _mapController = MapController();
  late double? _latitude;
  late double? _longitude;
  late double _radiusKm;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _radiusKm = widget.initialRadiusKm;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant LocationMapField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLatitude != widget.initialLatitude ||
        oldWidget.initialLongitude != widget.initialLongitude ||
        oldWidget.initialRadiusKm != widget.initialRadiusKm) {
      _latitude = widget.initialLatitude;
      _longitude = widget.initialLongitude;
      _radiusKm = widget.initialRadiusKm;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emit();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoint = _latitude != null && _longitude != null;
    final point = hasPoint ? LatLng(_latitude!, _longitude!) : null;
    final center = point ?? widget.defaultCenter;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9D2C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.helper,
            style: const TextStyle(
              color: Color(0xFF6E675F),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 240,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: hasPoint ? 12.5 : widget.defaultZoom,
                      onTap: (_, tappedPoint) {
                        setState(() {
                          _latitude = _roundCoordinate(tappedPoint.latitude);
                          _longitude = _roundCoordinate(tappedPoint.longitude);
                        });
                        _emit();
                        _mapController.move(tappedPoint, 12.5);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.smarteventhub.meloo',
                      ),
                      if (point != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: point,
                              radius: _radiusKm * 1000,
                              useRadiusInMeter: true,
                              color: const Color(0x3313AEBF),
                              borderColor: const Color(0xFF13AEBF),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (point != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 46,
                              height: 46,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF132A4A),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x2A132A4A),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.place_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _MapActionButton(
                          icon: Icons.add_rounded,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MapActionButton(
                          icon: Icons.remove_rounded,
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MapActionButton(
                          icon: Icons.my_location_rounded,
                          onTap: () => _mapController.move(
                            point ?? widget.defaultCenter,
                            hasPoint ? 12.5 : widget.defaultZoom,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xCC132A4A),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          'OpenStreetMap',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                label: hasPoint
                    ? 'Lat ${_latitude!.toStringAsFixed(5)}'
                    : 'Tap map to set location',
              ),
              if (hasPoint)
                _InfoPill(label: 'Lng ${_longitude!.toStringAsFixed(5)}'),
              _InfoPill(label: '${_radiusKm.toStringAsFixed(0)} km radius'),
            ],
          ),
          const SizedBox(height: 14),
          if (hasPoint)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => launchUrlString(
                  'https://www.openstreetmap.org/?mlat=${_latitude!.toStringAsFixed(6)}&mlon=${_longitude!.toStringAsFixed(6)}#map=14/${_latitude!.toStringAsFixed(6)}/${_longitude!.toStringAsFixed(6)}',
                  mode: LaunchMode.platformDefault,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open full map'),
              ),
            ),
          Text(
            widget.radiusLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: _radiusKm,
            min: 5,
            max: 250,
            divisions: 49,
            label: '${_radiusKm.toStringAsFixed(0)} km',
            onChanged: (value) {
              setState(() => _radiusKm = _roundRadius(value));
              _emit();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: hasPoint
                    ? () {
                        setState(() {
                          _latitude = null;
                          _longitude = null;
                        });
                        _emit();
                      }
                    : null,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear location'),
              ),
              const Text(
                'Tap anywhere on the map',
                style: TextStyle(
                  color: Color(0xFF7A7369),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _emit() {
    widget.onChanged(
      LocationSelection(
        latitude: _latitude,
        longitude: _longitude,
        radiusKm: _roundRadius(_radiusKm),
      ),
    );
  }

  double _roundCoordinate(double value) {
    return double.parse(value.toStringAsFixed(6));
  }

  double _roundRadius(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EEE2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1D4C2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4C463F),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: const Color(0xFF132A4A)),
        ),
      ),
    );
  }
}
