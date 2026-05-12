import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';
import type { DashboardRequest } from '@airnow/shared';

export class DashboardRequestDto implements DashboardRequest {
  @Type(() => Number)
  @IsLatitude()
  latitude!: number;

  @Type(() => Number)
  @IsLongitude()
  longitude!: number;
}
