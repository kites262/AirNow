import { Body, Controller, Inject, Post, HttpCode } from '@nestjs/common';

import { DashboardRequestDto } from './dashboard.dto';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(
    @Inject(DashboardService)
    private readonly dashboardService: DashboardService,
  ) {}

  @Post()
  @HttpCode(200)
  async getDashboard(@Body() request: DashboardRequestDto) {
    return this.dashboardService.getDashboard(request);
  }
}
