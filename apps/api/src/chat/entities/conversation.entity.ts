import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { ConversationParticipant } from './conversation-participant.entity';
import { Message } from './message.entity';

export enum ConversationType {
  DIRECT = 'direct',
  SUPPORT = 'support',
}

@Entity({ name: 'conversations' })
export class Conversation {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: ConversationType,
    default: ConversationType.DIRECT,
  })
  type!: ConversationType;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @OneToMany(
    () => ConversationParticipant,
    (participant) => participant.conversation,
    {
      cascade: true,
    },
  )
  participants!: ConversationParticipant[];

  @OneToMany(() => Message, (message) => message.conversation)
  messages!: Message[];
}
