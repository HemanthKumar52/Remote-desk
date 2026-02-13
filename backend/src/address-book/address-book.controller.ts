import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { AddressBookService } from './address-book.service';
import { JwtAuthGuard } from '../auth/guards';
import { CurrentUser } from '../common/decorators';

@Controller('address-book')
@UseGuards(JwtAuthGuard)
export class AddressBookController {
  constructor(private addressBookService: AddressBookService) {}

  @Post()
  async addEntry(
    @CurrentUser('id') userId: string,
    @Body() dto: { targetDeviceId: string; alias?: string; notes?: string },
  ) {
    return this.addressBookService.addEntry(userId, dto);
  }

  @Get()
  async getAll(@CurrentUser('id') userId: string) {
    return this.addressBookService.getAll(userId);
  }

  @Get('favorites')
  async getFavorites(@CurrentUser('id') userId: string) {
    return this.addressBookService.getFavorites(userId);
  }

  @Get('recent')
  async getRecent(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.addressBookService.getRecent(userId, limit ? Number(limit) : undefined);
  }

  @Get('search')
  async search(
    @CurrentUser('id') userId: string,
    @Query('q') query: string,
  ) {
    return this.addressBookService.search(userId, query);
  }

  @Patch(':id')
  async updateEntry(
    @CurrentUser('id') userId: string,
    @Param('id') entryId: string,
    @Body() dto: { alias?: string; notes?: string; isFavorite?: boolean },
  ) {
    return this.addressBookService.updateEntry(userId, entryId, dto);
  }

  @Post(':id/favorite')
  async toggleFavorite(
    @CurrentUser('id') userId: string,
    @Param('id') entryId: string,
  ) {
    return this.addressBookService.toggleFavorite(userId, entryId);
  }

  @Delete(':id')
  async deleteEntry(
    @CurrentUser('id') userId: string,
    @Param('id') entryId: string,
  ) {
    return this.addressBookService.deleteEntry(userId, entryId);
  }
}
