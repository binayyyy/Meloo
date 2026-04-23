import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  late double? _latitude;
  late double? _longitude;
  late double _radiusKm;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _radiusKm = widget.initialRadiusKm;
    _emit();
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
      _emit();
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
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: hasPoint ? 12.5 : widget.defaultZoom,
                  onTap: (_, tappedPoint) {
                    setState(() {
                      _latitude = tappedPoint.latitude;
                      _longitude = tappedPoint.longitude;
                    });
                    _emit();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'local.meloo.app',
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
              setState(() => _radiusKm = value);
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
        radiusKm: _radiusKm,
      ),
    );
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
