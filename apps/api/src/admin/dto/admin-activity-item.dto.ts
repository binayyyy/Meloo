export class AdminActivityItemDto {
  id!: string;
  type!: string;
  title!: string;
  detail!: string;
  status!: string | null;
  actorLabel!: string | null;
  createdAt!: string;
  resourceType!: string;
  resourceId!: string;
}
