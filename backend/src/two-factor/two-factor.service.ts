import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class TwoFactorService {
  constructor(private prisma: PrismaService) {}

  // Generate a random secret for TOTP
  generateSecret(): string {
    return crypto.randomBytes(20).toString('hex');
  }

  // Generate TOTP code based on secret and time
  generateTOTP(secret: string, timeStep = 30): string {
    const time = Math.floor(Date.now() / 1000 / timeStep);
    const timeBuffer = Buffer.alloc(8);
    timeBuffer.writeBigInt64BE(BigInt(time));

    const hmac = crypto.createHmac('sha1', Buffer.from(secret, 'hex'));
    hmac.update(timeBuffer);
    const hash = hmac.digest();

    const offset = hash[hash.length - 1] & 0xf;
    const code =
      ((hash[offset] & 0x7f) << 24) |
      ((hash[offset + 1] & 0xff) << 16) |
      ((hash[offset + 2] & 0xff) << 8) |
      (hash[offset + 3] & 0xff);

    return (code % 1000000).toString().padStart(6, '0');
  }

  // Verify TOTP code with time window tolerance
  verifyTOTP(secret: string, code: string, window = 1): boolean {
    const timeStep = 30;
    const currentTime = Math.floor(Date.now() / 1000 / timeStep);

    for (let i = -window; i <= window; i++) {
      const time = currentTime + i;
      const timeBuffer = Buffer.alloc(8);
      timeBuffer.writeBigInt64BE(BigInt(time));

      const hmac = crypto.createHmac('sha1', Buffer.from(secret, 'hex'));
      hmac.update(timeBuffer);
      const hash = hmac.digest();

      const offset = hash[hash.length - 1] & 0xf;
      const generatedCode =
        ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

      if ((generatedCode % 1000000).toString().padStart(6, '0') === code) {
        return true;
      }
    }
    return false;
  }

  // Setup 2FA for user
  async setup(userId: string) {
    const secret = this.generateSecret();

    // Store secret temporarily (not enabled yet)
    await this.prisma.user.update({
      where: { id: userId },
      data: { twoFactorSecret: secret },
    });

    // Generate QR code data for authenticator apps
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const otpAuthUrl = `otpauth://totp/SyncDesk:${user?.email}?secret=${this.toBase32(secret)}&issuer=SyncDesk`;

    return {
      secret: this.toBase32(secret),
      qrCodeUrl: otpAuthUrl,
    };
  }

  // Verify and enable 2FA
  async enable(userId: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user?.twoFactorSecret) {
      throw new BadRequestException('2FA setup not initiated');
    }

    if (!this.verifyTOTP(user.twoFactorSecret, code)) {
      throw new UnauthorizedException('Invalid verification code');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { twoFactorEnabled: true },
    });

    // Generate backup codes
    const backupCodes = this.generateBackupCodes();

    return {
      success: true,
      backupCodes,
    };
  }

  // Disable 2FA
  async disable(userId: string, code: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user?.twoFactorEnabled || !user?.twoFactorSecret) {
      throw new BadRequestException('2FA is not enabled');
    }

    if (!this.verifyTOTP(user.twoFactorSecret, code)) {
      throw new UnauthorizedException('Invalid verification code');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        twoFactorEnabled: false,
        twoFactorSecret: null,
      },
    });

    return { success: true };
  }

  // Verify 2FA code during login
  async verify(userId: string, code: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user?.twoFactorEnabled || !user?.twoFactorSecret) {
      return true; // 2FA not enabled, pass through
    }

    return this.verifyTOTP(user.twoFactorSecret, code);
  }

  // Check if user has 2FA enabled
  async isEnabled(userId: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    return user?.twoFactorEnabled ?? false;
  }

  // Generate backup codes
  private generateBackupCodes(count = 10): string[] {
    const codes: string[] = [];
    for (let i = 0; i < count; i++) {
      codes.push(crypto.randomBytes(4).toString('hex').toUpperCase());
    }
    return codes;
  }

  // Convert hex to base32 for authenticator apps
  private toBase32(hex: string): string {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    const bytes = Buffer.from(hex, 'hex');
    let bits = '';
    let result = '';

    for (const byte of bytes) {
      bits += byte.toString(2).padStart(8, '0');
    }

    for (let i = 0; i < bits.length; i += 5) {
      const chunk = bits.slice(i, i + 5).padEnd(5, '0');
      result += alphabet[parseInt(chunk, 2)];
    }

    return result;
  }
}
