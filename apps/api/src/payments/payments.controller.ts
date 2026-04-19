import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AccessTokenGuard } from '../common/guards/access-token.guard';
import { AuthenticatedUser } from '../common/interfaces/authenticated-user.interface';
import { CreateCheckoutSessionDto, PaymentCheckoutResponseDto } from './dto';
import { PaymentsService } from './payments.service';

@Controller()
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('events/:id/payments/checkout-session')
  @UseGuards(AccessTokenGuard)
  createCheckoutSession(
    @Param('id') eventId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateCheckoutSessionDto,
  ): Promise<PaymentCheckoutResponseDto> {
    return this.paymentsService.createCheckoutSession(eventId, user.sub, dto);
  }

  @Post('payments/stripe/sessions/:id/verify')
  @UseGuards(AccessTokenGuard)
  verifyStripeCheckoutSession(
    @Param('id') sessionId: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PaymentCheckoutResponseDto> {
    return this.paymentsService.verifyStripeCheckoutSession(sessionId, user.sub);
  }

  @Post('payments/stripe/webhook')
  @HttpCode(200)
  handleStripeWebhook(
    @Headers('stripe-signature') signature: string | undefined,
    @Req() request: { rawBody?: Buffer },
  ): Promise<{ received: true }> {
    return this.paymentsService.handleStripeWebhook(
      request.rawBody,
      signature,
    );
  }

  @Get('payments/my')
  @UseGuards(AccessTokenGuard)
  listMyPayments(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<PaymentCheckoutResponseDto[]> {
    return this.paymentsService.listMyPayments(user.sub);
  }
}
