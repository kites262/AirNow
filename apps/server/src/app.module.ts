import { Module } from '@nestjs/common';

import { DashboardModule } from './modules/dashboard/dashboard.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [HealthModule, DashboardModule],
})
export class AppModule {}
