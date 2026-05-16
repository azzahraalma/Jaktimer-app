String formatDistance(double? distance) {
  if (distance == null) return '-';

  if (distance < 1000) {
    return '${distance.toStringAsFixed(0)} m';
  } else {
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}