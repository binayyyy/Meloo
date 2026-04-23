export type CoordinateLike = {
  latitude: number | string | null;
  longitude: number | string | null;
};

export function toNullableNumber(value: unknown): number | null {
  if (value == null || value === '') {
    return null;
  }

  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : null;
  }

  const parsed = Number.parseFloat(String(value));
  return Number.isFinite(parsed) ? parsed : null;
}

export function hasCoordinates(
  value: Partial<CoordinateLike> | null | undefined,
): value is CoordinateLike {
  return (
    value != null &&
    toNullableNumber(value.latitude) != null &&
    toNullableNumber(value.longitude) != null
  );
}

export function haversineDistanceKm(
  left: CoordinateLike,
  right: CoordinateLike,
): number {
  const leftLatitude = toRadians(toNullableNumber(left.latitude)!);
  const leftLongitude = toRadians(toNullableNumber(left.longitude)!);
  const rightLatitude = toRadians(toNullableNumber(right.latitude)!);
  const rightLongitude = toRadians(toNullableNumber(right.longitude)!);

  const deltaLatitude = rightLatitude - leftLatitude;
  const deltaLongitude = rightLongitude - leftLongitude;

  const haversine =
    Math.sin(deltaLatitude / 2) ** 2 +
    Math.cos(leftLatitude) *
      Math.cos(rightLatitude) *
      Math.sin(deltaLongitude / 2) ** 2;

  const earthRadiusKm = 6371;
  const distance =
    2 * earthRadiusKm * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));

  return Number(distance.toFixed(1));
}

function toRadians(value: number): number {
  return (value * Math.PI) / 180;
}
