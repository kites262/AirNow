import { Injectable, Logger } from '@nestjs/common';
import axios, { isAxiosError } from 'axios';

type NominatimAddress = {
  road?: string;
  neighbourhood?: string;
  suburb?: string;
  highway?: string;
};

type NominatimResponse = {
  address: NominatimAddress;
};

@Injectable()
export class NominatimService {
  private readonly logger = new Logger(NominatimService.name);
  private readonly baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  private readonly userAgent = 'AirNow/1.0';

  async reverse(lat: number, lon: number): Promise<{ detail: string } | null> {
    try {
      const { data } = await axios.get<NominatimResponse>(this.baseUrl, {
        params: {
          lat,
          lon,
          format: 'json',
          zoom: 18,
          'accept-language': 'zh',
        },
        headers: { 'User-Agent': this.userAgent },
        timeout: 3000,
      });

      const detail = this.extractDetail(data.address);

      if (!detail) {
        return null;
      }

      return { detail };
    } catch (error) {
      if (isAxiosError(error)) {
        if (error.response?.status === 429) {
          this.logger.warn('Nominatim rate limited (429)');
          return null;
        }

        this.logger.warn(`Nominatim request failed: ${error.response?.status ?? error.message}`);
        return null;
      }

      this.logger.warn(`Nominatim unexpected error: ${error}`);
      return null;
    }
  }

  private extractDetail(address: NominatimAddress): string | null {
    return address.highway
      ?? address.road
      ?? address.neighbourhood
      ?? address.suburb
      ?? null;
  }
}
