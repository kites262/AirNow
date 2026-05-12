type CityProfile = {
  city: string;
  district: string;
  latitude: number;
  longitude: number;
};

const CITY_PROFILES: CityProfile[] = [
  { city: '北京', district: '朝阳区', latitude: 39.9042, longitude: 116.4074 },
  { city: '上海', district: '浦东新区', latitude: 31.2304, longitude: 121.4737 },
  { city: '广州', district: '天河区', latitude: 23.1291, longitude: 113.2644 },
  { city: '深圳', district: '南山区', latitude: 22.5431, longitude: 114.0579 },
  { city: '成都', district: '高新区', latitude: 30.5728, longitude: 104.0668 },
  { city: '杭州', district: '西湖区', latitude: 30.2741, longitude: 120.1551 },
];

export function resolveLocationFromCoordinates(latitude: number, longitude: number) {
  return CITY_PROFILES.reduce((closest, current) => {
    const currentDistance = distanceSquared(latitude, longitude, current.latitude, current.longitude);
    const closestDistance = distanceSquared(latitude, longitude, closest.latitude, closest.longitude);
    return currentDistance < closestDistance ? current : closest;
  }, CITY_PROFILES[0]);
}

function distanceSquared(latA: number, lonA: number, latB: number, lonB: number) {
  return (latA - latB) ** 2 + (lonA - lonB) ** 2;
}
