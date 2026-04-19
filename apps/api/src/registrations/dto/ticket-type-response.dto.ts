export class TicketTypeResponseDto {
  id!: string;
  eventId!: string;
  name!: string;
  price!: string;
  quantity!: number;
  remaining!: number;
  saleStartAt!: Date;
  saleEndAt!: Date;
}

