class Device {
  const Device({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.isOnline,
    required this.batteryLevel,
    required this.networkName,
    required this.firmwareVersion,
    required this.volume,
    required this.voiceName,
  });

  final String id;
  final String name;
  final String serialNumber;
  final bool isOnline;
  final int batteryLevel;
  final String networkName;
  final String firmwareVersion;
  final double volume;
  final String voiceName;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '小黄鸭',
      serialNumber: json['serialNumber']?.toString() ?? '',
      isOnline: json['isOnline'] == true,
      batteryLevel: _intValue(json['batteryLevel'], fallback: 0),
      networkName: json['networkName']?.toString() ?? '未连接 Wi-Fi',
      firmwareVersion: json['firmwareVersion']?.toString() ?? 'v1.0.0',
      volume: _doubleValue(
        json['volume'],
        fallback: 0.6,
      ).clamp(0.0, 1.0).toDouble(),
      voiceName: json['voiceName']?.toString() ?? '软萌小鸭音',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {'name': name, 'volume': volume, 'voiceName': voiceName};
  }

  Device copyWith({
    String? id,
    String? name,
    String? serialNumber,
    bool? isOnline,
    int? batteryLevel,
    String? networkName,
    String? firmwareVersion,
    double? volume,
    String? voiceName,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      networkName: networkName ?? this.networkName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      volume: volume ?? this.volume,
      voiceName: voiceName ?? this.voiceName,
    );
  }
}

int _intValue(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(dynamic value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
